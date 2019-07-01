# frozen_string_literal: true

module Gitlab
  module Graphql
    module FindArgumentInParent
      # Searches up the GraphQL AST and returns the first matching argument
      # passed to a node
      def self.find(parent, argument, limit_depth: nil)
        argument = argument.to_s.camelize(:lower).to_sym
        depth = 0

        while parent.respond_to?(:parent)
          args = node_args(parent)
          return args[argument] if args.key?(argument)

          depth += 1
          return if limit_depth && depth >= limit_depth

          parent = parent.parent
        end
      end

      class << self
        private

        def node_args(node)
          node.irep_node.arguments
        end
      end
    end
  end
end
