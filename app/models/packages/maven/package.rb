# frozen_string_literal: true

module Packages
  module Maven
    class Package < Packages::Package
      self.allow_legacy_sti_class = true

      has_one :maven_metadatum, inverse_of: :package, class_name: 'Packages::Maven::Metadatum'

      accepts_nested_attributes_for :maven_metadatum

      validates :version, format: { with: Gitlab::Regex.maven_version_regex }, if: -> { version? }
      validates :name, format: { with: Gitlab::Regex.package_name_regex }

      def self.only_maven_packages_with_path(path, use_cte: false)
        if use_cte
          # This is an optimization fence which assumes that looking up the Metadatum record by path (globally)
          # and then filter down the packages (by project or by group and subgroups) will be cheaper than
          # looking up all packages within a project or group and filter them by path.

          inner_query = Packages::Maven::Metadatum.where(path: path).select(:id, :package_id)
          cte = Gitlab::SQL::CTE.new(:maven_metadata_by_path, inner_query)
          with(cte.to_arel)
            .joins('INNER JOIN maven_metadata_by_path ON maven_metadata_by_path.package_id=packages_packages.id')
        else
          joins(:maven_metadatum).where(packages_maven_metadata: { path: path })
        end
      end

      def sync_maven_metadata(user)
        return unless version? && user

        ::Packages::Maven::Metadata::SyncWorker.perform_async(user.id, project_id, name)
      end
    end
  end
end
