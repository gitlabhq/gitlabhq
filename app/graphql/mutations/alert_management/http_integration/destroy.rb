# frozen_string_literal: true

module Mutations
  module AlertManagement
    module HttpIntegration
      class Destroy < HttpIntegrationBase
        graphql_name 'HttpIntegrationDestroy'

        authorize_granular_token permissions: :delete_http_integration,
          boundary_argument: :id, boundary: :project, boundary_type: :project

        argument :id, Types::GlobalIDType[::AlertManagement::HttpIntegration],
          required: true,
          description: "ID of the integration to remove."

        def resolve(id:)
          integration = authorized_find!(id: id)

          response ::AlertManagement::HttpIntegrations::DestroyService.new(
            integration,
            current_user
          ).execute
        end
      end
    end
  end
end
