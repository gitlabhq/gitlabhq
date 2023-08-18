# frozen_string_literal: true

module Mutations
  module AlertManagement
    module HttpIntegration
      class ResetToken < HttpIntegrationBase
        graphql_name 'HttpIntegrationResetToken'

        argument :id, Types::GlobalIDType[::AlertManagement::HttpIntegration],
          required: true,
          description: "ID of the integration to mutate."

        def resolve(id:)
          integration = authorized_find!(id: id)

          response ::AlertManagement::HttpIntegrations::UpdateService.new(
            integration,
            current_user,
            regenerate_token: true
          ).execute
        end
      end
    end
  end
end
