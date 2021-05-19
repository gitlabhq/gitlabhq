# frozen_string_literal: true

module Mutations
  module AlertManagement
    module HttpIntegration
      class HttpIntegrationBase < BaseMutation
        field :integration,
              Types::AlertManagement::HttpIntegrationType,
              null: true,
              description: "The HTTP integration."

        authorize :admin_operations

        private

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_class: ::AlertManagement::HttpIntegration)
        end

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

Mutations::AlertManagement::HttpIntegration::HttpIntegrationBase.prepend_mod_with('Mutations::AlertManagement::HttpIntegration::HttpIntegrationBase')
