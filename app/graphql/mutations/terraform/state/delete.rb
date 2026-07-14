# frozen_string_literal: true

module Mutations
  module Terraform
    module State
      class Delete < Base
        graphql_name 'TerraformStateDelete'

        authorize_granular_token permissions: :delete_terraform_state, boundary_argument: :id, boundary: :project,
          boundary_type: :project

        def resolve(id:)
          state = authorized_find!(id: id)
          response = ::Terraform::States::TriggerDestroyService.new(state, current_user: current_user).execute

          { errors: response.errors }
        end
      end
    end
  end
end
