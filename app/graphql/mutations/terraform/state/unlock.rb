# frozen_string_literal: true

module Mutations
  module Terraform
    module State
      class Unlock < Base
        graphql_name 'TerraformStateUnlock'

        def resolve(id:)
          state = authorized_find!(id: id)
          state.update(lock_xid: nil, locked_by_user: nil, locked_at: nil)

          { errors: errors_on_object(state) }
        end
      end
    end
  end
end
