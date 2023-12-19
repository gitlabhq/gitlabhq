# frozen_string_literal: true

module Mutations
  module AlertManagement
    module PrometheusIntegration
      class PrometheusIntegrationBase < BaseMutation
        field :integration,
          Types::AlertManagement::PrometheusIntegrationType,
          null: true,
          description: "Newly created integration."

        authorize :admin_project

        private

        def response(integration, result)
          {
            integration: integration,
            errors: Array(result[:message])
          }
        end

        def integration_attributes(args)
          {
            prometheus_integration_attributes: {
              manual_configuration: args[:active],
              api_url: args[:api_url]
            }.compact
          }
        end

        def token_attributes
          { alerting_setting_attributes: { regenerate_token: true } }
        end
      end
    end
  end
end
