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

        unless instance_integration
          integration_class.id_in(exclusions.map(&:id)).delete_all
          return ServiceResponse.success(payload: exclusions)
        end

        ::Integrations::Propagation::BulkUpdateService.new(instance_integration, exclusions).execute
        ServiceResponse.success(payload: exclusions)
      end
    end
  end
end
