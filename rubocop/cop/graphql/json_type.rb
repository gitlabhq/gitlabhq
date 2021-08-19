# frozen_string_literal: true

# This cop checks for use of GraphQL::Types::JSON types in GraphQL fields
# and arguments.
#
# @example
#
#   # bad
#   class AwfulClass
#     field :some_field, GraphQL::Types::JSON
#   end
#
#   # good
#   class GreatClass
#     field :some_field, GraphQL::Types::String
#   end

module RuboCop
  module Cop
    module Graphql
      class JSONType < RuboCop::Cop::Cop
        MSG = 'Avoid using GraphQL::Types::JSON. See: ' \
              'https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#json'

        def_node_matcher :has_json_type?, <<~PATTERN
          (send nil? {:field :argument}
            (sym _)
            (const
              (const
                (const nil? :GraphQL) :Types) :JSON)
            (...)?)
        PATTERN

        def on_send(node)
          add_offense(node, location: :expression) if has_json_type?(node)
        end
      end
    end
  end
end
