# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCatalogResourceVersionSemVer < BatchedMigrationJob
      feature_category :pipeline_composition

      scope_to ->(relation) { relation.where(semver_major: nil) }
      operation_name :backfill_catalog_resource_versions_sem_var

      def perform
        each_sub_batch do |sub_batch|
          with_release_tag(sub_batch).each do |version|
            match_data = ::Gitlab::Regex.semver_regex.match(normalized_version_name(version.tag))

            next unless match_data

            version.update!(
              semver_major: match_data[1].to_i,
              semver_minor: match_data[2].to_i,
              semver_patch: match_data[3].to_i,
              semver_prerelease: match_data[4]
            )
          end
        end
      end

      private

      def with_release_tag(sub_batch)
        sub_batch
          .joins('INNER JOIN releases ON releases.id = catalog_resource_versions.release_id')
          .select('catalog_resource_versions.*, releases.tag')
      end

      # Removes `v` prefix and converts partial or extended semver
      # numbers into a normalized format. Examples:
      #
      # 1         => 1.0.0
      # v1.2      => 1.2.0
      # 1.2-alpha => 1.2.0-alpha
      # 1.0+123   => 1.0.0+123
      # 1.2.3.4   => 1.2.3
      #
      def normalized_version_name(name)
        name = name.capitalize.delete_prefix('V')

        first_part, *other_parts = name.split(/([-,+])/)
        dot_count = first_part.count('.')

        return name unless dot_count != 2 && /^[\d.]+$/.match?(first_part)

        if dot_count < 2
          add_zeroes = '.0' * (2 - dot_count)

          [first_part, add_zeroes, *other_parts].join
        else
          # Assuming the format is 1.2.3.4, we only want to keep the first 3 digits.
          truncated_first_part = first_part.split(/([.])/)[0..4]

          [truncated_first_part, *other_parts].join
        end
      end
    end
  end
end
