# frozen_string_literal: true

module Types
  module Ci
    module Inputs
      # rubocop:disable Graphql/AuthorizeTypes -- authorized by parent Ci::Inputs::SpecType
      class ConditionType < BaseObject
        graphql_name 'CiInputsCondition'
        description 'Condition node in rule expression tree.'

        field :field, GraphQL::Types::String,
          null: true,
          description: 'Input field name for comparison nodes.'

        field :operator, GraphQL::Types::String,
          null: false,
          description: 'Operator type: equals, not_equals, AND, OR.'

        field :value, GraphQL::Types::String,
          null: true,
          description: 'Expected value for comparison nodes.'

        field :children, [Types::Ci::Inputs::ConditionType],
          null: true,
          description: 'Child conditions for AND/OR nodes.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
