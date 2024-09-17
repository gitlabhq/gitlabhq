# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RemoveNamespaceFromOsTypeSbomComponents < BatchedMigrationJob
      operation_name :remove_namespace_from_os_type_sbom_components
      feature_category :software_composition_analysis

      INDEX_NAME = 'index_sbom_components_on_component_type_name_and_purl_type'
      OTHER_INDEX = 'idx_sbom_components_on_name_purl_type_component_type_and_org_id'

      OS_PURL_TYPES = {
        apk: 9,
        rpm: 10,
        deb: 11,
        'cbl-mariner': 12,
        wolfi: 13
      }.with_indifferent_access.freeze

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where(purl_type: OS_PURL_TYPES.values)
            .where(component_type: 0)
            .where('name LIKE ?', '%/%')
            .each do |component| # rubocop:disable Rails/FindEach -- using find_each is not needed here because of the slow iteration implementation
            component.update!(name: delete_os_namespace_prefix(component.name))
          rescue ActiveRecord::RecordNotUnique => e # rubocop:disable BackgroundMigration/AvoidSilentRescueExceptions -- we catch a specific known not unique error
            raise unless e.message.include?(INDEX_NAME) || e.message.include?(OTHER_INDEX)

            Gitlab::BackgroundMigration::Logger.warn(
              message: "Error updating sbom_component name based on #{INDEX_NAME}",
              model_id: component.id
            )
          end
        end
      end

      private

      def delete_os_namespace_prefix(previous_name)
        _, new_name = previous_name.split('/', 2)

        new_name
      end
    end
  end
end
