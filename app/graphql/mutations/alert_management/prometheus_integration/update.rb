# frozen_string_literal: true

module Mutations
  module AlertManagement
    module PrometheusIntegration
      class Update < PrometheusIntegrationBase
        graphql_name 'PrometheusIntegrationUpdate'

        argument :id, Types::GlobalIDType[::Integrations::Prometheus],
                 required: true,
                 description: "The ID of the integration to mutate."

        argument :active, GraphQL::Types::Boolean,
                 required: false,
                 description: "Whether the integration is receiving alerts."

        argument :api_url, GraphQL::Types::String,
                 required: false,
                 description: "Endpoint at which Prometheus can be queried."

        def resolve(args)
          integration = authorized_find!(id: args[:id])

          result = ::Projects::Operations::UpdateService.new(
            integration.project,
            current_user,
            integration_attributes(args)
          ).execute

          response integration.reset, result
        end
      end
    end
  end
end
