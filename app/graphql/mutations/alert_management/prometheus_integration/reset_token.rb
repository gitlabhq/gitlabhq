# frozen_string_literal: true

# Deprecated:
#   Remove from MutationType during any major release.
module Mutations
  module AlertManagement
    module PrometheusIntegration
      class ResetToken < HttpIntegration::ResetToken
        graphql_name 'PrometheusIntegrationResetToken'

        field :integration,
          Types::AlertManagement::PrometheusIntegrationType,
          null: true,
          description: "Updated integration."

        argument :id, Types::GlobalIDType[::Integrations::Prometheus],
          required: true,
          description: "ID of the integration to mutate."

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
