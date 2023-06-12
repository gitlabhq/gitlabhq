# frozen_string_literal: true

module Packages
  module Nuget
    class PackagesMetadataPresenter
      include Packages::Nuget::PresenterHelpers
      include Gitlab::Utils::StrongMemoize

      COUNT = 1

      def initialize(packages)
        @packages = packages
                    .preload_nuget_files
                    .preload_nuget_metadatum
                    .including_tags
                    .including_dependency_links_with_nuget_metadatum
      end

      def count
        COUNT
      end

      def items
        [summary]
      end

      private

      def summary
        packages_with_metadata = @packages.map { |pkg| metadata_for(pkg) }

        {
          json_url: json_url,
          lower_version: lower_version,
          upper_version: upper_version,
          packages_count: packages_with_metadata.size,
          packages: packages_with_metadata
        }
      end

      def metadata_for(package)
        {
          json_url: json_url_for(package),
          archive_url: archive_url_for(package),
          catalog_entry: catalog_entry_for(package)
        }
      end

      def json_url
        json_url_for(@packages.first)
      end

      def lower_version
        sorted_versions.first
      end

      def upper_version
        sorted_versions.last
      end

      def sorted_versions
        versions = @packages.filter_map(&:version)
        sort_versions(versions)
      end
      strong_memoize_attr :sorted_versions
    end
  end
end
