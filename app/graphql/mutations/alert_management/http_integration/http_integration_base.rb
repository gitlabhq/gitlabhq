# frozen_string_literal: true

module Mutations
  module AlertManagement
    module HttpIntegration
      class HttpIntegrationBase < BaseMutation
        field :integration,
          Types::AlertManagement::HttpIntegrationType,
          null: true,
          description: "Alerting integration."

        authorize :admin_operations

        private

        def response(result)
          {
            integration: result.payload[:integration],
            errors: result.errors
          }
        end

        # overriden in EE
        def http_integration_params(_project, args)
          args.slice(:name, :active, :type_identifier)
        end
      end
    end
  end
end

Mutations::AlertManagement::HttpIntegration::HttpIntegrationBase.prepend_mod
