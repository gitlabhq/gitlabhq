# frozen_string_literal: true

# This cop ensures that if a class uses `graphql_name`, then
# it's the first line of the class
#
# @example
#
#   # bad
#   class AwfulClass
#     field :some_field, GraphQL::Types::JSON
#     graphql_name 'AwfulClass'
#   end
#
#   # good
#   class GreatClass
#     graphql_name 'AwfulClass'
#     field :some_field, GraphQL::Types::String
#   end

module RuboCop
  module Cop
    module Graphql
      class GraphqlNamePosition < RuboCop::Cop::Base
        MSG = '`graphql_name` should be the first line of the class: '\
              'https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#naming-conventions'

        def_node_search :graphql_name?, <<~PATTERN
          (send nil? :graphql_name ...)
        PATTERN

        def on_class(node)
          return unless graphql_name?(node)
          return if node.body.single_line?

          add_offense(node) unless graphql_name?(node.body.children.first)
        end
      end
    end
  end
end
