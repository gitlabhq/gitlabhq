# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillTerraformModulesMetadataWithSemver < BatchedMigrationJob
      TERRAFORM_MODULE_PACKAGE_TYPE = 12
      INSTALLABLE_STATUS = [0, 1].freeze

      operation_name :backfill_terraform_modules_metadata_with_semver
      feature_category :package_registry
      scope_to ->(relation) { relation.where(package_type: TERRAFORM_MODULE_PACKAGE_TYPE, status: INSTALLABLE_STATUS) } # rubocop:disable Database/AvoidScopeTo -- scoped columns are backed by an index

      class ModuleMetadatum < ::ApplicationRecord
        self.table_name = 'packages_terraform_module_metadata'

        attribute :fields, default: -> { {} }

        validates :semver_major, :semver_minor, numericality: { only_integer: true, less_than: 2**31 }
      end

      def perform
        each_sub_batch do |sub_batch|
          process_batch_of_packages(sub_batch)
        end
      end

      private

      def process_batch_of_packages(pkgs)
        metadata = pkgs.filter_map do |pkg|
          semver = ::Gitlab::Regex.semver_regex.match(pkg.version)
          next unless semver

          build_metadatum(pkg, semver)
        end

        return unless metadata.any?

        upsert_metadata(metadata)
      end

      def build_metadatum(pkg, semver)
        metadatum = ModuleMetadatum.new(
          package_id: pkg.id,
          project_id: pkg.project_id,
          semver_major: semver[1].to_i,
          semver_minor: semver[2].to_i,
          semver_patch: semver[3].to_i,
          semver_prerelease: semver[4]
        )
        return metadatum.attributes.except('created_at', 'updated_at') if metadatum.valid?

        log_invalid_metadata(pkg, metadatum)
        nil
      end

      def upsert_metadata(metadata)
        ModuleMetadatum.upsert_all(
          metadata,
          update_only: %i[semver_major semver_minor semver_patch semver_prerelease],
          returning: false
        )
      end

      def log_invalid_metadata(pkg, metadatum)
        Gitlab::BackgroundMigration::Logger.warn(
          message: 'Invalid semver data for terraform module',
          package_id: pkg.id,
          version: pkg.version,
          error: metadatum.errors.full_messages.to_sentence
        )
      end
    end
  end
end
