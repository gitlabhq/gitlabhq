# frozen_string_literal: true

module Types
  module Terraform
    class StateType < BaseObject
      graphql_name 'TerraformState'

      authorize :read_terraform_state

      connection_type_class(Types::CountableConnectionType)

      field :id, GraphQL::Types::ID,
            null: false,
            description: 'ID of the Terraform state.'

      field :name, GraphQL::Types::String,
            null: false,
            description: 'Name of the Terraform state.'

      field :locked_by_user, Types::UserType,
            null: true,
            description: 'The user currently holding a lock on the Terraform state.'

      field :locked_at, Types::TimeType,
            null: true,
            description: 'Timestamp the Terraform state was locked.'

      field :latest_version, Types::Terraform::StateVersionType,
            complexity: 3,
            null: true,
            description: 'The latest version of the Terraform state.'

      field :created_at, Types::TimeType,
            null: false,
            description: 'Timestamp the Terraform state was created.'

      field :updated_at, Types::TimeType,
            null: false,
            description: 'Timestamp the Terraform state was updated.'

      def locked_by_user
        Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.locked_by_user_id).find
      end
    end
  end
end
