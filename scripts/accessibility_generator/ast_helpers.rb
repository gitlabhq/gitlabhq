# frozen_string_literal: true

require 'rubocop'

# Shared AST helpers for accessibility generator
module AstHelpers
  extend RuboCop::AST::NodePattern::Macros

  ASSERTION_METHODS = %i[expect assert aggregate_failures].freeze

  # Node matcher for assertion contexts (expect, assert, aggregate_failures)
  def_node_matcher :assertion_call?, <<~PATTERN
    {
      (send nil? {:expect :assert :aggregate_failures} ...)
      (send (send nil? {:expect :assert :aggregate_failures} ...) ...)
    }
  PATTERN

  # Check if a node is within an assertion context by walking up the tree
  def in_assertion_context?(node)
    current = node
    while current
      return true if assertion_call?(current)

      if current.block_type?
        send_node = current.send_node
        return true if send_node && ASSERTION_METHODS.include?(send_node.method_name)
      end

      current = current.parent
    end

    false
  end

  # Parse a Ruby file into an AST
  def parse_file(content)
    version = RUBY_VERSION[/^(\d+\.\d+)/, 1].to_f
    RuboCop::AST::ProcessedSource.new(content, version).ast
  end
end
