# frozen_string_literal: true

module Types
  module Terraform
    class StateType < BaseObject
      graphql_name 'TerraformState'

      authorize :read_terraform_state

      field :id, GraphQL::ID_TYPE,
            null: false,
            description: 'ID of the Terraform state'

      field :name, GraphQL::STRING_TYPE,
            null: false,
            description: 'Name of the Terraform state'

      field :locked_by_user, Types::UserType,
            null: true,
            authorize: :read_user,
            description: 'The user currently holding a lock on the Terraform state',
            resolve: -> (state, _, _) { Gitlab::Graphql::Loaders::BatchModelLoader.new(User, state.locked_by_user_id).find }

      field :locked_at, Types::TimeType,
            null: true,
            description: 'Timestamp the Terraform state was locked'

      field :created_at, Types::TimeType,
            null: false,
            description: 'Timestamp the Terraform state was created'

      field :updated_at, Types::TimeType,
            null: false,
            description: 'Timestamp the Terraform state was updated'
    end
  end
end
