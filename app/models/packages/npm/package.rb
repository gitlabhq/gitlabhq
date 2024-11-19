# frozen_string_literal: true

module Packages
  module Npm
    class Package < Packages::Package
      self.allow_legacy_sti_class = true

      has_one :npm_metadatum, inverse_of: :package, class_name: 'Packages::Npm::Metadatum'

      validate :npm_package_already_taken

      validates :name, format: {
        with: Gitlab::Regex.npm_package_name_regex,
        message: Gitlab::Regex.npm_package_name_regex_message
      }

      validates :version, format: {
        with: Gitlab::Regex.semver_regex,
        message: Gitlab::Regex.semver_regex_message
      }

      scope :preload_npm_metadatum, -> { preload(:npm_metadatum) }

      scope :with_npm_scope, ->(scope) do
        where(
          "position('/' in packages_packages.name) > 0 AND split_part(packages_packages.name, '/', 1) = :package_scope",
          package_scope: "@#{sanitize_sql_like(scope)}"
        )
      end

      def sync_npm_metadata_cache
        ::Packages::Npm::CreateMetadataCacheWorker.perform_async(project_id, name)
      end

      private

      def npm_package_already_taken
        return unless follows_npm_naming_convention?
        return unless project&.package_already_taken?(name, version, package_type: :npm)

        errors.add(:base, _('Package already exists'))
      end

      # https://docs.gitlab.com/ee/user/packages/npm_registry/#package-naming-convention
      def follows_npm_naming_convention?
        return false unless project&.root_namespace&.path

        project.root_namespace.path == ::Packages::Npm.scope_of(name)
      end
    end
  end
end
