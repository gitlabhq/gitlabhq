# frozen_string_literal: true

module Packages
  module Nuget
    class Package < Packages::Package
      self.allow_legacy_sti_class = true

      # `deprecated` is npm-only, so excluding it keeps NuGet lookups on the
      # `status = ANY (ARRAY[0, 1])` partial index (idx_pkgs_project_id_lower_name_when_nuget_installable_version).
      INSTALLABLE_STATUSES = [:default, :hidden].freeze

      has_many :installable_nuget_package_files, -> {
        installable.with_nuget_format
      }, class_name: 'Packages::PackageFile', inverse_of: :package

      has_one :nuget_metadatum, inverse_of: :package, class_name: 'Packages::Nuget::Metadatum'
      has_many :nuget_symbols, inverse_of: :package, class_name: 'Packages::Nuget::Symbol'

      validates :name, format: { with: Gitlab::Regex.nuget_package_name_regex }
      validates :version, format: { with: Gitlab::Regex.nuget_version_regex }

      scope :with_nuget_version_or_normalized_version, ->(version, with_normalized: true) do
        relation = with_case_insensitive_version(version)

        return relation unless with_normalized

        relation
          .left_joins(:nuget_metadatum)
          .or(
            merge(Packages::Nuget::Metadatum.normalized_version_in(version))
          )
      end

      scope :without_nuget_temporary_name, -> { where.not(name: Packages::Nuget::TEMPORARY_PACKAGE_NAME) }

      scope :including_dependency_links_with_nuget_metadatum, -> do
        includes(dependency_links: [:dependency, :nuget_metadatum])
      end

      scope :preload_nuget_metadatum, -> { preload(:nuget_metadatum) }
      scope :preload_nuget_files, -> { preload(:installable_nuget_package_files) }

      def self.installable_statuses
        INSTALLABLE_STATUSES
      end

      def normalized_nuget_version
        nuget_metadatum&.normalized_version
      end
    end
  end
end
