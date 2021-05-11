# frozen_string_literal: true

module Mutations
  module AlertManagement
    module HttpIntegration
      class Update < HttpIntegrationBase
        graphql_name 'HttpIntegrationUpdate'

        argument :id, Types::GlobalIDType[::AlertManagement::HttpIntegration],
                 required: true,
                 description: "The ID of the integration to mutate."

        argument :name, GraphQL::STRING_TYPE,
                 required: false,
                 description: "The name of the integration."

        argument :active, GraphQL::BOOLEAN_TYPE,
                 required: false,
                 description: "Whether the integration is receiving alerts."

        def resolve(args)
          integration = authorized_find!(id: args[:id])

          response ::AlertManagement::HttpIntegrations::UpdateService.new(
            integration,
            current_user,
            http_integration_params(integration.project, args)
          ).execute
        end
      end
    end
  end
end

Mutations::AlertManagement::HttpIntegration::Update.prepend_mod_with('Mutations::AlertManagement::HttpIntegration::Update')
