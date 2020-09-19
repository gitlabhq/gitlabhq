# frozen_string_literal: true

module RuboCop
  # Common code used to implement cops checking routes outside of /-/ scope.
  #
  # Examples:
  # * RuboCop::Cop::PutProjectRoutesUnderScope
  # * RuboCop::Cop::PutGroupRoutesUnderScope
  module RoutesUnderScope
    ROUTE_METHODS = Set.new(%i[resource resources get post put patch delete]).freeze

    def on_send(node)
      return unless route_method?(node)
      return unless outside_scope?(node)
      return if root_route?(node)

      add_offense(node)
    end

    def outside_scope?(node)
      node.each_ancestor(:block).none? do |parent|
        dash_scope?(parent.to_a.first)
      end
    end

    def route_method?(node)
      ROUTE_METHODS.include?(node.method_name)
    end

    def root_route?(node)
      first_argument = node.arguments.first

      if first_argument.respond_to?(:value)
        first_argument.value == '/'
      end
    end
  end
end
