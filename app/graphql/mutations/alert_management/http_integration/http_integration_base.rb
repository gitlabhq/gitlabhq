# frozen_string_literal: true

module Mutations
  module AlertManagement
    module HttpIntegration
      class HttpIntegrationBase < BaseMutation
        field :integration,
          Types::AlertManagement::HttpIntegrationType,
          null: true,
          description: "HTTP integration."

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
          args.slice(:name, :active)
        end
      end
    end
  end
end

Mutations::AlertManagement::HttpIntegration::HttpIntegrationBase.prepend_mod
