# frozen_string_literal: true

require 'rubocop'
require 'active_support/core_ext/enumerable'
require_relative 'ast_helpers'

# Extracts metadata from E2E test files using RuboCop AST with node patterns
class E2EMetadataExtractor
  extend RuboCop::AST::NodePattern::Macros
  include RuboCop::AST::Traversal
  include AstHelpers

  # Match it blocks with optional testcase argument
  def_node_matcher :it_block_with_args, <<~PATTERN
    (block
      (send nil? :it
        (str $_description)
        (hash $...)?
      )
      ...
    )
  PATTERN

  # Match perform blocks with Page:: constant receiver
  def_node_matcher :page_perform_block, <<~PATTERN
    (block
      (send
        (const (const ...) $_page_class)
        :perform
      )
      ...
    )
  PATTERN

  # Match describe calls with string argument
  def_node_matcher :describe_call, <<~PATTERN
    (send nil? :describe (str $_context) ...)
  PATTERN

  # Match visit! calls (without arguments)
  def_node_matcher :visit_bang_call?, <<~PATTERN
    (send nil? :visit! ...)
  PATTERN

  # Match visit calls with string argument
  def_node_matcher :visit_call, <<~PATTERN
    (send nil? :visit (str $_path) ...)
  PATTERN

  # Match page interaction calls (show.click_something, page.select_something, etc.)
  def_node_matcher :page_interaction_call, <<~PATTERN
    (send
      (send nil? {:show :page :form :file :project})
      $_method ...)
  PATTERN

  # Match Flow:: calls
  def_node_matcher :flow_call, <<~PATTERN
    (send
      (const nil? :Flow)
      $_method ...)
  PATTERN

  def initialize(gitlab_root)
    @gitlab_root = gitlab_root
  end

  def extract_metadata(e2e_tests)
    e2e_tests.each do |test|
      file_path = File.join(@gitlab_root, test['path'])
      next unless File.exist?(file_path)

      source = File.read(file_path)
      ast = parse_file(source)
      next unless ast

      # Initialize collectors
      @it_blocks = []
      @page_interactions = []
      @describe_context = nil

      # Walk the AST - this calls on_block and on_send automatically
      walk(ast)

      # Assign extracted metadata
      test['it_blocks'] = @it_blocks
      test['page_interactions'] = @page_interactions.uniq
      test['describe_context'] = @describe_context
    end
  end

  private

  # Callback for block nodes during AST traversal
  def on_block(node)
    # Handle it blocks
    result = it_block_with_args(node)
    extract_it_block_metadata(node) if result

    # Handle Page::* perform blocks
    extract_page_perform_interaction(node) if page_perform_block(node)

    super # Continue traversal into nested nodes
  end

  def extract_it_block_metadata(node)
    description, *hash_pairs = it_block_with_args(node)
    it_block = { 'description' => description }

    # Extract testcase URL from hash arguments if present
    # hash_pairs is an array of individual pair nodes from the hash
    hash_pairs.each do |pair|
      next unless pair.is_a?(RuboCop::AST::Node) && pair.pair_type?

      key, value = *pair
      if key.sym_type? && key.value == :testcase && value.str_type?
        it_block['testcase_url'] = value.value
        break
      end
    end

    @it_blocks << it_block
  end

  def extract_page_perform_interaction(node)
    receiver = node.send_node.receiver
    return unless receiver&.const_type?

    const_parts = receiver.source.split('::')
    return unless const_parts.first == 'Page' && const_parts.size > 1

    page_name = const_parts[1..].join(' ').downcase
    @page_interactions << "interacts with #{page_name}"
  end

  # Callback for send nodes during AST traversal
  def on_send(node)
    # Handle describe calls
    context = describe_call(node)
    @describe_context ||= context if context

    # Handle visit calls with path argument
    path = visit_call(node)
    @page_interactions << "visits #{path}" if path

    # Handle visit! calls
    @page_interactions << 'visits project page' if visit_bang_call?(node)

    # Handle page interaction calls (show.click_something, etc.)
    method_name = page_interaction_call(node)
    if method_name && %i[perform expect aggregate_failures].exclude?(node.method_name)
      extract_page_interaction(method_name)
    end

    # Handle Flow:: calls
    flow_method = flow_call(node)
    if flow_method
      action = flow_method.to_s.tr('_', ' ')
      @page_interactions << "#{action} (flow)"
    end

    super # Continue traversal into nested nodes
  end

  def extract_page_interaction(method_name)
    method_str = method_name.to_s
    return if method_str.start_with?('has_', 'have_')

    # Convert snake_case to human readable
    human_readable = method_str.tr('_', ' ')
    @page_interactions << human_readable
  end
end
