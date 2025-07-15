# frozen_string_literal: true

module RuboCop
  module Cop
    module Graphql
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
      class JSONType < RuboCop::Cop::Base
        MSG = 'Avoid using GraphQL::Types::JSON. See: ' \
              'https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#json'

        # @!method has_json_type?(node)
        def_node_matcher :has_json_type?, <<~PATTERN
          (send nil? {:field :argument}
            (sym _)
            (const
              (const
                (const nil? :GraphQL) :Types) :JSON)
            (...)?)
        PATTERN

        def on_send(node)
          add_offense(node) if has_json_type?(node)
        end
      end
    end
  end
end
