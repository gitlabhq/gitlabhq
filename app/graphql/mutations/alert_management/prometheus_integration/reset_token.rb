# frozen_string_literal: true

module Mutations
  module AlertManagement
    module PrometheusIntegration
      class ResetToken < PrometheusIntegrationBase
        graphql_name 'PrometheusIntegrationResetToken'

        argument :id, Types::GlobalIDType[::PrometheusService],
                 required: true,
                 description: "The id of the integration to mutate"

        def resolve(id:)
          integration = authorized_find!(id: id)

          result = ::Projects::Operations::UpdateService.new(
            integration.project,
            current_user,
            token_attributes
          ).execute

          response integration, result
        end
      end
    end
  end
end
