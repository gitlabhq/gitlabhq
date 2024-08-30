# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class UpdateSbomComponentsNameBasedOnPep503 < BatchedMigrationJob
      operation_name :update_component_name_based_on_pep_503
      scope_to ->(relation) { relation.where(purl_type: 8).where("name LIKE ?", "%.%") }
      feature_category :software_composition_analysis

      INDEX_NAME = 'index_sbom_components_on_component_type_name_and_purl_type'
      OTHER_INDEX_NAME = 'idx_sbom_components_on_name_purl_type_component_type_and_org_id'

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.each do |component|
            component.update!(name: normalized_name(component.name))
          rescue ActiveRecord::RecordNotUnique => e # rubocop:disable BackgroundMigration/AvoidSilentRescueExceptions -- this is only silent when related to INDEX_NAME
            raise unless e.message.include?(INDEX_NAME) || e.message.include?(OTHER_INDEX_NAME)

            Gitlab::BackgroundMigration::Logger.warn(
              message: "Error updating sbom_component name based on #{INDEX_NAME}",
              model_id: component.id
            )
          end
        end
      end

      private

      def normalized_name(name)
        name.gsub(Sbom::PackageUrl::Normalizer::PYPI_REGEX, '-')
      end
    end
  end
end
