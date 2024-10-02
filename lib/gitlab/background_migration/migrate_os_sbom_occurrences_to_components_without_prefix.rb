# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateOsSbomOccurrencesToComponentsWithoutPrefix < BatchedMigrationJob
      OS_PURL_TYPES = [
        9,  # apk
        10, # rpm
        11, # deb
        12, # cbl-mariner
        13  # wolfi
      ].freeze

      LIBRARY_COMPONENT_TYPE = 0

      COMPONENT_VERSIONS_UNIQUE_BY = %i[component_id version].freeze
      COMPONENT_VERSIONS_RETURNS = %i[id version].freeze

      OCCURRENCE_BATCH_SIZE = 100

      operation_name :migrate_os_sbom_occurrences_to_components_without_prefix
      feature_category :software_composition_analysis
      scope_to ->(relation) do
        relation
          .where(component_type: LIBRARY_COMPONENT_TYPE)
          .where(purl_type: OS_PURL_TYPES)
      end

      # This struct serves as a small performance improvement. With it,
      # we avoid allocating an array that would require freezing, and
      # gain attribute accessors.
      UpdatedOccurrenceValues = Struct.new(:id, :component_version_id, :component_id, :component_name)

      class Component < ::ApplicationRecord
        self.table_name = 'sbom_components'

        has_many :occurrences
        has_many :component_versions
      end

      class ComponentVersion < ::ApplicationRecord
        self.table_name = 'sbom_component_versions'

        belongs_to :component, optional: false
      end

      class Occurrence < ::ApplicationRecord
        self.table_name = 'sbom_occurrences'

        belongs_to :component, optional: false
        belongs_to :component_version
      end

      # rubocop:disable Metrics/AbcSize -- It went above limit when adding support for organization_id sharding key.
      def perform
        each_sub_batch do |sub_batch|
          # rubocop:disable Rails/FindEach -- This already operates on a sub_batch
          sub_batch.where("name LIKE '%/%'").each do |src_component|
            dst_component = Component.find_by(
              name: component_name_without_os_prefix(src_component.name),
              purl_type: src_component.purl_type,
              component_type: src_component.component_type,
              organization_id: src_component.organization_id
            )

            # This uses loop based batching to efficiently iterate over
            # all occurrences. Since we update the component_id column,
            # this will eventually return no results and break out of the
            # loop.
            loop do
              occurrences = Occurrence.includes(:component_version)
                .where(component_id: src_component.id)
                .limit(OCCURRENCE_BATCH_SIZE)

              break unless occurrences.present?

              component_version_attributes = build_component_version_attributes(dst_component, occurrences)

              component_versions = bulk_upsert_component_versions(component_version_attributes).to_h do |row|
                [row['version'], row['id']]
              end

              values = occurrences.map do |occurrence|
                dst_component_version_id = component_versions[occurrence.component_version&.version]

                UpdatedOccurrenceValues.new(occurrence.id, dst_component_version_id, dst_component.id,
                  dst_component.name)
              end

              bulk_update_occurrence_values(values)
            end
          end
          # rubocop:enable Rails/FindEach
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      def component_name_without_os_prefix(name)
        _component_os_prefix, component_name = name.split('/', 2)

        component_name
      end

      def build_component_version_attributes(dst_component, occurrences)
        occurrences.filter_map do |occurrence|
          next unless occurrence.component_version.present?

          { component_id: dst_component.id, version: occurrence.component_version.version,
            organization_id: dst_component.organization_id,
            source_package_name: occurrence.component_version.source_package_name }
        end
      end

      def bulk_upsert_component_versions(attributes)
        return unless attributes.present?

        attributes = attributes.uniq { |values| values.with_indifferent_access.slice(*COMPONENT_VERSIONS_UNIQUE_BY) }

        ComponentVersion.upsert_all(attributes, unique_by: COMPONENT_VERSIONS_UNIQUE_BY,
          returning: COMPONENT_VERSIONS_RETURNS)
      end

      def bulk_update_occurrence_values(values)
        values_expression = Arel::Nodes::ValuesList.new(values).to_sql

        update_statement = <<~SQL
        WITH "updated_values" (id, component_version_id, component_id, component_name) AS (
        #{values_expression}
        )
        UPDATE "sbom_occurrences"
        SET "updated_at" = CURRENT_TIMESTAMP,
        "component_version_id" = "updated_values"."component_version_id"::bigint,
        "component_id" = "updated_values"."component_id",
        "component_name" = "updated_values"."component_name"
        FROM "updated_values"
        WHERE "sbom_occurrences"."id" = "updated_values"."id"
        SQL

        connection.execute(update_statement)
      end
    end
  end
end
