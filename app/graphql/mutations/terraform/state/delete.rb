# frozen_string_literal: true

module Mutations
  module Terraform
    module State
      class Delete < Base
        graphql_name 'TerraformStateDelete'

        def resolve(id:)
          state = authorized_find!(id: id)
          response = ::Terraform::States::TriggerDestroyService.new(state, current_user: current_user).execute

          { errors: response.errors }
        end
      end
    end
  end
end
