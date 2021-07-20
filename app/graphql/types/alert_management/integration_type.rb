# frozen_string_literal: true

module Types
  module AlertManagement
    module IntegrationType
      include Types::BaseInterface
      graphql_name 'AlertManagementIntegration'

      field :id,
            GraphQL::ID_TYPE,
            null: false,
            description: 'ID of the integration.'

      field :type,
            AlertManagement::IntegrationTypeEnum,
            null: false,
            description: 'Type of integration.'

      field :name,
            GraphQL::STRING_TYPE,
            null: true,
            description: 'Name of the integration.'

      field :active,
            GraphQL::BOOLEAN_TYPE,
            null: true,
            description: 'Whether the endpoint is currently accepting alerts.'

      field :token,
            GraphQL::STRING_TYPE,
            null: true,
            description: 'Token used to authenticate alert notification requests.'

      field :url,
            GraphQL::STRING_TYPE,
            null: true,
            description: 'Endpoint which accepts alert notifications.'

      field :api_url,
            GraphQL::STRING_TYPE,
            null: true,
            description: 'URL at which Prometheus metrics can be queried to populate the metrics dashboard.'

      definition_methods do
        def resolve_type(object, context)
          if object.is_a?(::Integrations::Prometheus)
            Types::AlertManagement::PrometheusIntegrationType
          else
            Types::AlertManagement::HttpIntegrationType
          end
        end
      end

      orphan_types Types::AlertManagement::PrometheusIntegrationType,
                   Types::AlertManagement::HttpIntegrationType
    end
  end
end
