# frozen_string_literal: true

module Types
  module Ci
    module Inputs
      # rubocop:disable Graphql/AuthorizeTypes -- authorized by parent Ci::Inputs::SpecType
      class RuleType < BaseObject
        graphql_name 'CiInputsRule'
        description 'Conditional rule for dynamic input options'

        field :condition_tree, Types::Ci::Inputs::ConditionType,
          null: true,
          description: 'Parsed condition tree for frontend eval.'

        field :default, GraphQL::Types::String,
          null: true,
          hash_key: 'default',
          description: 'Default value when rule matches.'

        field :if, GraphQL::Types::String,
          null: true,
          hash_key: 'if',
          description: 'Condition expression.'

        field :options, [GraphQL::Types::String],
          null: true,
          hash_key: 'options',
          description: 'Available options when rule matches.'

        def condition_tree
          return @condition_tree if defined?(@condition_tree)

          if_clause = object['if']
          return @condition_tree = nil unless if_clause

          statement = Gitlab::Ci::Pipeline::Expression::Statement.new(if_clause)
          @condition_tree = Gitlab::Ci::Inputs::RulesConverter.new.convert(statement.parse_tree)
        rescue Gitlab::Ci::Pipeline::Expression::ExpressionError => e
          raise GraphQL::ExecutionError, "Invalid expression in rule: #{e.message}"
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
