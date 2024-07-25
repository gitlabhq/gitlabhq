# frozen_string_literal: true

module Packages
  module Nuget
    class SearchResultsPresenter
      include Packages::Nuget::PresenterHelpers
      include Gitlab::Utils::StrongMemoize

      delegate :total_count, to: :@search

      def initialize(search)
        @search = search
      end

      def data
        return [] if total_count == 0

        grouped_packages.map do |package_name, packages|
          package_versions, latest_version, latest_package = extract_package_details(packages)

          {
            type: 'Package',
            name: package_name,
            version: latest_version,
            versions: package_versions,
            total_downloads: 0,
            verified: true,
            tags: tags_for(latest_package),
            metadatum: metadatum_for(latest_package)
          }
        end
      end
      strong_memoize_attr :data

      private

      def grouped_packages
        @search
          .results
          .preload_nuget_metadatum
          .preload_tags
          .group_by(&:name)
      end

      def extract_package_details(packages)
        package_versions = []
        latest_version = nil
        latest_package = nil

        packages.each do |pkg|
          package_versions << {
            json_url: json_url_for(pkg),
            downloads: 0,
            version: pkg.version
          }

          if sort_versions([latest_version, pkg.version]).last == pkg.version
            latest_version = pkg.version
            latest_package = pkg
          end
        end

        [package_versions, latest_version, latest_package]
      end
    end
  end
end
