# frozen_string_literal: true

# This cop checks for missing GraphQL field descriptions.
#
# @example
#
#   # bad
#   class AwfulClass
#     field :some_field, GraphQL::STRING_TYPE
#   end
#
#   class TerribleClass
#     argument :some_argument, GraphQL::STRING_TYPE
#   end
#
#   # good
#   class GreatClass
#     argument :some_field,
#       GraphQL::STRING_TYPE,
#       description: "Well described - a superb description"
#
#     field :some_field,
#       GraphQL::STRING_TYPE,
#       description: "A thorough and compelling description"
#   end

module RuboCop
  module Cop
    module Graphql
      class Descriptions < RuboCop::Cop::Cop
        MSG = 'Please add a `description` property.'

        # ability_field and permission_field set a default description.
        def_node_matcher :fields, <<~PATTERN
          (send nil? :field $...)
        PATTERN

        def_node_matcher :arguments, <<~PATTERN
          (send nil? :argument $...)
        PATTERN

        def_node_matcher :has_description?, <<~PATTERN
          (hash <(pair (sym :description) _) ...>)
        PATTERN

        def on_send(node)
          matches = fields(node) || arguments(node)

          return if matches.nil?

          add_offense(node, location: :expression) unless has_description?(matches.last)
        end
      end
    end
  end
end
