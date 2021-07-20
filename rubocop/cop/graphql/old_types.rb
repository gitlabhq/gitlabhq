# frozen_string_literal: true

# This cop checks for use of older GraphQL  types in GraphQL fields
# and arguments.
# GraphQL::ID_TYPE, GraphQL::INT_TYPE, GraphQL::STRING_TYPE, GraphQL::BOOLEAN_TYPE
#
# @example
#
#   # bad
#   class AwfulClass
#     field :some_field, GraphQL::STRING_TYPE
#   end
#
#   # good
#   class GreatClass
#     field :some_field, GraphQL::Types::String
#   end

module RuboCop
  module Cop
    module Graphql
      class OldTypes < RuboCop::Cop::Cop
        MSG_ID      = 'Avoid using GraphQL::ID_TYPE. Use GraphQL::Types::ID instead'
        MSG_INT     = 'Avoid using GraphQL::INT_TYPE. Use GraphQL::Types::Int instead'
        MSG_STRING  = 'Avoid using GraphQL::STRING_TYPE. Use GraphQL::Types::String instead'
        MSG_BOOLEAN = 'Avoid using GraphQL::BOOLEAN_TYPE. Use GraphQL::Types::Boolean instead'

        def_node_matcher :has_old_type?, <<~PATTERN
          (send nil? {:field :argument}
            (sym _)
            (const (const nil? :GraphQL) ${:ID_TYPE :INT_TYPE :STRING_TYPE :BOOLEAN_TYPE})
            (...)?)
        PATTERN

        def on_send(node)
          old_constant = has_old_type?(node)
          return unless old_constant

          add_offense(node, location: :expression, message: "#{self.class}::MSG_#{old_constant[0..-6]}".constantize)
        end
      end
    end
  end
end
