# frozen_string_literal: true

module Packages
  module Nuget
    module PresenterHelpers
      include ::API::Helpers::RelatedResourcesHelpers

      BLANK_STRING = ''
      PACKAGE_DEPENDENCY_GROUP = 'PackageDependencyGroup'
      PACKAGE_DEPENDENCY = 'PackageDependency'
      NUGET_PACKAGE_FORMAT = 'nupkg'

      private

      def json_url_for(package)
        path = api_v4_projects_packages_nuget_metadata_package_name_package_version_path(
          {
            id: package.project_id,
            package_name: package.name,
            package_version: package.version,
            format: '.json'
          },
          true
        )

        expose_url(path)
      end

      def archive_url_for(package)
        path = api_v4_projects_packages_nuget_download_package_name_package_version_package_filename_path(
          {
            id: package.project_id,
            package_name: package.name,
            package_version: package.version,
            package_filename: package.package_files.with_format(NUGET_PACKAGE_FORMAT).last&.file_name
          },
          true
        )

        expose_url(path)
      end

      def catalog_entry_for(package)
        {
          json_url: json_url_for(package),
          authors: BLANK_STRING,
          dependency_groups: dependency_groups_for(package),
          package_name: package.name,
          package_version: package.version,
          archive_url: archive_url_for(package),
          summary: BLANK_STRING,
          tags: tags_for(package),
          metadatum: metadatum_for(package)
        }
      end

      def dependency_groups_for(package)
        base_nuget_id = "#{json_url_for(package)}#dependencyGroup"

        dependency_links_grouped_by_target_framework(package).map do |target_framework, dependency_links|
          nuget_id = target_framework_nuget_id(base_nuget_id, target_framework)
          {
            id: nuget_id,
            type: PACKAGE_DEPENDENCY_GROUP,
            target_framework: target_framework,
            dependencies: dependencies_for(nuget_id, dependency_links)
          }.compact
        end
      end

      def dependency_links_grouped_by_target_framework(package)
        package
          .dependency_links
          .includes_dependency
          .preload_nuget_metadatum
          .group_by { |dependency_link| dependency_link.nuget_metadatum&.target_framework }
      end

      def dependencies_for(nuget_id, dependency_links)
        return [] if dependency_links.empty?

        dependency_links.map do |dependency_link|
          dependency = dependency_link.dependency
          {
            id: "#{nuget_id}/#{dependency.name.downcase}",
            type: PACKAGE_DEPENDENCY,
            name: dependency.name,
            range: dependency.version_pattern
          }
        end
      end

      def target_framework_nuget_id(base_nuget_id, target_framework)
        target_framework.blank? ? base_nuget_id : "#{base_nuget_id}/#{target_framework.downcase}"
      end

      def metadatum_for(package)
        metadatum = package.nuget_metadatum
        return {} unless metadatum

        metadatum.slice(:project_url, :license_url, :icon_url)
                  .compact
      end

      def base_path_for(package)
        api_v4_projects_packages_nuget_path(id: package.project_id)
      end

      def tags_for(package)
        package.tag_names.join(::Packages::Tag::NUGET_TAGS_SEPARATOR)
      end
    end
  end
end
