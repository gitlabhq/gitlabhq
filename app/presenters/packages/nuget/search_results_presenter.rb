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
        strong_memoize(:data) do
          @search.results.group_by(&:name).map do |package_name, packages|
            latest_version = latest_version(packages)
            latest_package = packages.find { |pkg| pkg.version == latest_version }

            {
              type: 'Package',
              authors: '',
              name: package_name,
              version: latest_version,
              versions: build_package_versions(packages),
              summary: '',
              total_downloads: 0,
              verified: true,
              tags: tags_for(latest_package),
              metadatum: metadatum_for(latest_package)
            }
          end
        end
      end

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
        versions = packages.map(&:version).compact
        VersionSorter.sort(versions).last # rubocop: disable Style/RedundantSort
      end
    end
  end
end
