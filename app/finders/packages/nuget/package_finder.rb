# frozen_string_literal: true

module Packages
  module Nuget
    class PackageFinder < ::Packages::GroupOrProjectPackageFinder
      MAX_PACKAGES_COUNT = 300
      FORCE_NORMALIZATION_CLIENT_VERSION = '>= 3'

      def execute
        return ::Packages::Package.none unless @params[:package_name].present?

        packages.limit_recent(@params[:limit] || MAX_PACKAGES_COUNT)
      end

      private

      def packages
        result = find_by_name
        find_by_version(result)
      end

      def find_by_name
        base
          .nuget
          .has_version
          .with_case_insensitive_name(@params[:package_name])
      end

      def find_by_version(result)
        return result if @params[:package_version].blank?

        result
          .with_nuget_version_or_normalized_version(
            @params[:package_version],
            with_normalized: client_forces_normalized_version?
          )
      end

      def client_forces_normalized_version?
        return true if @params[:client_version].blank?

        VersionSorter.compare(FORCE_NORMALIZATION_CLIENT_VERSION, @params[:client_version]) <= 0
      end
    end
  end
end
