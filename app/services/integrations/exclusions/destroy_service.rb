# frozen_string_literal: true

module Integrations
  module Exclusions
    class DestroyService < BaseService
      def execute
        result = validate
        return result if result.present?

        destroy_exclusions
      end

      private

      def destroy_exclusions
        exclusions = integration_model.from_union([
          integration_model.with_custom_settings.by_active_flag(false).for_group(groups),
          integration_model.with_custom_settings.exclusions_for_project(projects)
        ])

        return ServiceResponse.success(payload: []) unless exclusions.present?

        unless instance_integration
          # rubocop:disable Cop/DestroyAll -- loading objects into memory to run callbacks and return objects
          return ServiceResponse.success(payload: exclusions.destroy_all)
          # rubocop:enable Cop/DestroyAll
        end

        ::Integrations::Propagation::BulkUpdateService.new(instance_integration, exclusions).execute

        group_exclusions = exclusions.select(&:group_level?)
        group_exclusions.each do |exclusion|
          PropagateIntegrationWorker.perform_async(exclusion.id)
        end

        ServiceResponse.success(payload: exclusions)
      end
    end
  end
end
