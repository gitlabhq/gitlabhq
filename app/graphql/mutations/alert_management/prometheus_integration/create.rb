# frozen_string_literal: true

# Deprecated:
#   Remove from MutationType during any major release.
module Mutations
  module AlertManagement
    module PrometheusIntegration
      class Create < HttpIntegration::Create
        graphql_name 'PrometheusIntegrationCreate'

        field :integration,
          Types::AlertManagement::PrometheusIntegrationType,
          null: true,
          description: "Newly created integration."

        argument :name, GraphQL::Types::String,
          required: false,
          description: 'Name of the integration.',
          default_value: 'Prometheus'

        argument :api_url, GraphQL::Types::String,
          required: false,
          description: 'Endpoint at which Prometheus can be queried.',
          deprecated: { reason: 'Feature removed in 16.0', milestone: '18.2' }

        def resolve(args)
          super(args.merge(name: 'Prometheus', type_identifier: :prometheus))
        end
      end
    end
  end
end
