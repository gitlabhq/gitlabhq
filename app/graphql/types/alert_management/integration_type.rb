# frozen_string_literal: true

module Types
  module AlertManagement
    module IntegrationType
      include Types::BaseInterface
      graphql_name 'AlertManagementIntegration'

      field :id,
        GraphQL::Types::ID,
        null: false,
        description: 'ID of the integration.'

      field :type,
        AlertManagement::IntegrationTypeEnum,
        null: false,
        description: 'Type of integration.'

      field :name,
        GraphQL::Types::String,
        null: true,
        description: 'Name of the integration.'

      field :active,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Whether the endpoint is currently accepting alerts.'

      field :token,
        GraphQL::Types::String,
        null: true,
        description: 'Token used to authenticate alert notification requests.'

      field :url,
        GraphQL::Types::String,
        null: true,
        description: 'Endpoint which accepts alert notifications.'

      field :api_url,
        GraphQL::Types::String,
        null: true,
        description: 'URL at which Prometheus metrics can be queried to populate the metrics dashboard.',
        deprecated: { reason: 'Feature removed in 16.0', milestone: '18.2' }

      def type
        object.type_identifier.to_sym
      end

      def api_url
        nil
      end

      definition_methods do
        def resolve_type(object, context)
          if object.type_identifier == 'prometheus'
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
