# frozen_string_literal: true

module RuboCop
  module Cop
    module Graphql
      # This cop checks for missing GraphQL type annotations on resolvers
      #
      # @example
      #
      #   # bad
      #   module Resolvers
      #     class NoTypeResolver < BaseResolver
      #       field :some_field, GraphQL::Types::String
      #     end
      #   end
      #
      #   # good
      #   module Resolvers
      #     class WithTypeResolver < BaseResolver
      #       type MyType, null: true
      #
      #       field :some_field, GraphQL::Types::String
      #     end
      #   end
      class ResolverType < RuboCop::Cop::Base
        MSG = 'Missing type annotation: Please add `type` DSL method call. ' \
          'e.g: type UserType.connection_type, null: true'

        # @!method typed?(node)
        def_node_matcher :typed?, <<~PATTERN
          (... (begin <(send nil? :type ...) ...>))
        PATTERN

        def on_class(node)
          add_offense(node) if resolver?(node) && !typed?(node)
        end

        private

        def resolver?(node)
          node.loc.name.source.end_with?('Resolver')
        end
      end
    end
  end
end
