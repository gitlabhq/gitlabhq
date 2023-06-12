# frozen_string_literal: true

module Packages
  module Nuget
    class SearchResultsPresenter
      include Packages::Nuget::PresenterHelpers
      include Gitlab::Utils::StrongMemoize

      delegate :total_count, to: :@search

      def initialize(search)
        @search = search
        @package_versions = {}
      end

      def data
        @search.results.group_by(&:name).map do |package_name, packages|
          latest_version = latest_version(packages)
          latest_package = packages.find { |pkg| pkg.version == latest_version }

          {
            type: 'Package',
            name: package_name,
            version: latest_version,
            versions: build_package_versions(packages),
            total_downloads: 0,
            verified: true,
            tags: tags_for(latest_package),
            metadatum: metadatum_for(latest_package)
          }
        end
      end
      strong_memoize_attr :data

      private

      def build_package_versions(packages)
        packages.map do |pkg|
          {
            json_url: json_url_for(pkg),
            downloads: 0,
            version: pkg.version
          }
        end
      end

      def latest_version(packages)
        versions = packages.filter_map(&:version)
        sort_versions(versions).last
      end
    end
  end
end
