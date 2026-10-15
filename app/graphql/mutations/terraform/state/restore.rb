# frozen_string_literal: true

module Mutations
  module Terraform
    module State
      class Restore < BaseMutation
        graphql_name 'TerraformStateRestore'
        description 'Restores a soft-deleted Terraform state. The state is not restored ' \
          'when terraform_state_delayed_deletion is disabled.'
        authorize :restore_terraform_state
        authorize_granular_token permissions: :restore_terraform_state, boundary_argument: :id, boundary: :project,
          boundary_type: :project
        argument :id,
          Types::GlobalIDType[::Terraform::State],
          required: true,
          description: 'Global ID of the Terraform state.'
        field :errors,
          [GraphQL::Types::String],
          null: false,
          description: 'Errors encountered during restore.'
        field :terraform_state,
          Types::Terraform::StateType,
          null: true,
          description: 'Terraform state after restore.'
        def resolve(id:)
          state = authorized_find!(id: id)
          raise_resource_not_available_error! if Feature.disabled?(:terraform_state_delayed_deletion, state.project)
          response = ::Terraform::States::RestoreService
            .new(state, current_user: current_user)
            .execute
          {
            terraform_state: response.payload[:terraform_state],
            errors: response.errors
          }
        end
      end
    end
  end
end
