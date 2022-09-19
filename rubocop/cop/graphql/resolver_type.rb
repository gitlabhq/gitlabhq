# frozen_string_literal: true

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

module RuboCop
  module Cop
    module Graphql
      class ResolverType < RuboCop::Cop::Base
        MSG = 'Missing type annotation: Please add `type` DSL method call. ' \
          'e.g: type UserType.connection_type, null: true'

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
