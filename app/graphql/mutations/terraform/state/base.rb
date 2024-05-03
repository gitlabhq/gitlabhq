# frozen_string_literal: true

module Mutations
  module Terraform
    module State
      class Base < BaseMutation
        authorize :admin_terraform_state

        argument :id,
          Types::GlobalIDType[::Terraform::State],
          required: true,
          description: 'Global ID of the Terraform state.'
      end
    end
  end
end
