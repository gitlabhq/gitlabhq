# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class UpdateSbomOccurrencesComponentNameBasedOnPep503 < BatchedMigrationJob
      operation_name :update_occurrence_component_name_based_on_pep_503
      feature_category :software_composition_analysis

      def perform
        each_sub_batch do |sub_batch|
          update_occurrence_component_name(sub_batch)
        end
      end

      private

      def normalized_name(name)
        connection.quote(name.gsub(Sbom::PackageUrl::Normalizer::PYPI_REGEX, '-'))
      end

      def update_occurrence_component_name(batch)
        occurrences = batch
          .joins("INNER JOIN sbom_components ON sbom_occurrences.component_id = sbom_components.id")
          .where("sbom_components.purl_type = 8 AND sbom_occurrences.component_name LIKE '%.%'")

        return if occurrences.blank?

        values_list = occurrences.map do |occurrence|
          "(#{occurrence.id}, #{normalized_name(occurrence.component_name)})"
        end.join(", ")

        sql = <<~SQL
          WITH new_values (id, component_name) AS (
            VALUES
              #{values_list}
          )
          UPDATE sbom_occurrences
          SET component_name = new_values.component_name
          FROM new_values
          WHERE sbom_occurrences.id = new_values.id
        SQL

        connection.execute(sql)
      end
    end
  end
end
