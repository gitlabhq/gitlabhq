# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class InstanceVariableType < BaseObject
      graphql_name 'CiInstanceVariable'
      description 'CI/CD variables for a GitLab instance.'

      implements VariableInterface

      field :id, GraphQL::Types::ID,
        null: false,
        description: 'ID of the variable.'

      field :description, GraphQL::Types::String,
        null: true,
        description: 'Description of the variable.'

      field :environment_scope, GraphQL::Types::String,
        null: true,
        deprecated: {
          reason: 'No longer used, only available for GroupVariableType and ProjectVariableType',
          milestone: '15.3'
        },
        description: 'Scope defining the environments that can use the variable.'

      field :protected, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is protected.'

      field :masked, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is masked.'

      field :raw, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is raw.'

      def environment_scope
        nil
      end
    end
  end
end
