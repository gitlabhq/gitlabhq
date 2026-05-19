# frozen_string_literal: true

require 'rubocop'
require 'active_support/core_ext/string/filters'
require_relative 'ast_helpers'

# Extracts code patterns from feature test files using RuboCop AST with node patterns
class CodePatternExtractor
  extend RuboCop::AST::NodePattern::Macros
  include RuboCop::AST::Traversal
  include AstHelpers

  MAX_PATTERNS_PER_CATEGORY = 3
  MAX_LINE_LENGTH = 80

  # Match let/let_it_be blocks that contain a create call (directly or in descendants)
  def_node_matcher :let_block?, <<~PATTERN
    (block
      (send nil? {:let :let_it_be} ...)
      ...)
  PATTERN

  # Match visit method calls
  def_node_matcher :visit_call?, <<~PATTERN
    (send nil? :visit ...)
  PATTERN

  # Match interaction method calls
  def_node_matcher :interaction_call?, <<~PATTERN
    (send nil? {:fill_in :click_button :click_link :select_listbox_item} ...)
  PATTERN

  # Match within_testid blocks and extract testid value
  def_node_matcher :within_testid_block, <<~PATTERN
    (block
      (send nil? :within_testid (str $_testid))
      _args
      $_body)
  PATTERN

  def initialize(gitlab_root)
    @gitlab_root = gitlab_root
  end

  def extract_patterns(feature_test_files)
    code_patterns = {
      'setup' => [],
      'navigation' => [],
      'interaction' => []
    }

    feature_test_files.each do |file|
      file_path = File.join(@gitlab_root, file)
      next unless File.exist?(file_path)

      begin
        content = File.read(file_path)
      rescue Errno::EACCES, Errno::EIO => e
        warn "Warning: Could not read #{file_path}: #{e.message}"
        next
      end

      ast = parse_file(content)
      next unless ast

      # Initialize pattern collectors
      @setup_patterns = []
      @navigation_patterns = []
      @interaction_patterns = []

      # Walk the AST - this calls on_block and on_send automatically
      walk(ast)

      # Collect patterns from this file
      code_patterns['setup'].concat(@setup_patterns)
      code_patterns['navigation'].concat(@navigation_patterns)
      code_patterns['interaction'].concat(@interaction_patterns)
    end

    # Keep only unique patterns and limit to max per category
    code_patterns.each do |category, patterns|
      code_patterns[category] = patterns
        .uniq
        .compact
        .reject(&:empty?)
        .first(MAX_PATTERNS_PER_CATEGORY)
    end

    code_patterns
  end

  private

  # Callback for block nodes during AST traversal
  def on_block(node)
    # Handle let/let_it_be blocks with create calls
    if let_block?(node) && contains_create_call?(node) && node.source.lines.count == 1
      @setup_patterns << node.source.strip
    end

    # Handle within_testid blocks
    result = within_testid_block(node)
    if result
      testid, body = result
      pattern = extract_within_testid_pattern(testid, body)
      @interaction_patterns << pattern if pattern
    end

    super # Continue traversal into nested nodes
  end

  # Check if a block contains a create call anywhere in its descendants
  def contains_create_call?(node)
    node.each_descendant(:send).any? { |send_node| send_node.method_name == :create }
  end

  # Callback for send nodes during AST traversal
  def on_send(node)
    unless in_assertion_context?(node)
      # Handle visit calls
      if visit_call?(node)
        source = node.source.strip
        @navigation_patterns << source.truncate(MAX_LINE_LENGTH)
      end

      # Handle interaction calls
      @interaction_patterns << node.source.strip if interaction_call?(node) && node.source.lines.count == 1
    end

    super # Continue traversal into nested nodes
  end

  def extract_within_testid_pattern(testid, body_node)
    return unless body_node

    # Get top-level statements in the block (not nested)
    statements = body_node.begin_type? ? body_node.children : [body_node]

    # Find first non-assertion action
    first_action = statements.find do |statement|
      statement.send_type? && !assertion_call?(statement)
    end

    return unless first_action

    "within_testid('#{testid}') do\n      #{first_action.source.strip}\nend"
  end
end
