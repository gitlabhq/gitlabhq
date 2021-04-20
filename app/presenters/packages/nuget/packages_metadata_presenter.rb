# frozen_string_literal: true

module Packages
  module Nuget
    class PackagesMetadataPresenter
      include Packages::Nuget::PresenterHelpers
      include Gitlab::Utils::StrongMemoize

      COUNT = 1

      def initialize(packages)
        @packages = packages
      end

      def count
        COUNT
      end

      def items
        [summary]
      end

      private

      def summary
        {
          json_url: json_url,
          lower_version: lower_version,
          upper_version: upper_version,
          packages_count: @packages.count,
          packages: @packages.map { |pkg| metadata_for(pkg) }
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
        strong_memoize(:sorted_versions) do
          versions = @packages.map(&:version).compact
          VersionSorter.sort(versions)
        end
      end
    end
  end
end
