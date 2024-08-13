# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class InheritedCiVariableType < BaseObject
      graphql_name 'InheritedCiVariable'
      description 'CI/CD variables a project inherites from its parent group and ancestors.'

      field :id, GraphQL::Types::ID,
        null: false,
        description: 'ID of the variable.'

      field :key, GraphQL::Types::String,
        null: true,
        description: 'Name of the variable.'

      field :description, GraphQL::Types::String,
        null: true,
        description: 'Description of the variable.'

      field :raw, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is raw.'

      field :variable_type, ::Types::Ci::VariableTypeEnum,
        null: true,
        description: 'Type of the variable.'

      field :environment_scope, GraphQL::Types::String,
        null: true,
        description: 'Scope defining the environments that can use the variable.'

      field :protected, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is protected.'

      field :masked, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is masked.'

      field :hidden, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is hidden.'

      field :group_name, GraphQL::Types::String,
        null: true,
        description: 'Indicates group the variable belongs to.'

      field :group_ci_cd_settings_path, GraphQL::Types::String,
        null: true,
        description: 'Indicates the path to the CI/CD settings of the group the variable belongs to.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
