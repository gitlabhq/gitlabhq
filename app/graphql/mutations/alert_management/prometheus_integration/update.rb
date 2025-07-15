# frozen_string_literal: true

# Deprecated:
#   Remove from MutationType during any major release.
module Mutations
  module AlertManagement
    module PrometheusIntegration
      class Update < HttpIntegration::Update
        graphql_name 'PrometheusIntegrationUpdate'

        field :integration,
          Types::AlertManagement::PrometheusIntegrationType,
          null: true,
          description: "Updated integration."

        argument :id, Types::GlobalIDType[::Integrations::Prometheus],
          required: true,
          description: "ID of the integration to mutate."

        argument :api_url, GraphQL::Types::String,
          required: false,
          description: "Endpoint at which Prometheus can be queried.",
          deprecated: { reason: 'Feature removed in 16.0', milestone: '18.2' }

        def resolve(args)
          super(args.except(:name))
        end

        def authorized_find!(**)
          integration = super&.project
            &.alert_management_http_integrations
            &.for_endpoint_identifier('legacy-prometheus')
            &.take

          integration || raise_resource_not_available_error!
        end
      end
    end
  end
end
