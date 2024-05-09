# frozen_string_literal: true

module Integrations
  module Exclusions
    class DestroyService < BaseService
      def execute
        super do
          destroy_exclusions
        end
      end

      private

      def destroy_exclusions
        integration_class = Integration.integration_name_to_model(integration_name)
        exclusions = integration_class.exclusions_for_project(projects)

        return ServiceResponse.success(payload: []) unless exclusions.present?

        instance_integration = integration_class.for_instance.first

        return ServiceResponse.success(payload: exclusions.destroy_all) unless instance_integration # rubocop: disable Cop/DestroyAll -- We load exclusions so we can have the deleted exclusions in the response

        ::Integrations::Propagation::BulkUpdateService.new(instance_integration, exclusions).execute
        ServiceResponse.success(payload: exclusions)
      end
    end
  end
end
