# frozen_string_literal: true

module Mutations
  module Terraform
    module State
      class Delete < Base
        graphql_name 'TerraformStateDelete'

        def resolve(id:)
          state = authorized_find!(id: id)
          state.destroy

          { errors: errors_on_object(state) }
        end
      end
    end
  end
end
