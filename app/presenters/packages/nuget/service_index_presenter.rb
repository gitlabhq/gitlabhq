# frozen_string_literal: true

module Packages
  module Nuget
    class ServiceIndexPresenter
      include API::Helpers::RelatedResourcesHelpers

      SERVICE_VERSIONS = {
        download: %w[PackageBaseAddress/3.0.0],
        search: %w[SearchQueryService SearchQueryService/3.0.0-beta SearchQueryService/3.0.0-rc],
        publish: %w[PackagePublish/2.0.0],
        metadata: %w[RegistrationsBaseUrl RegistrationsBaseUrl/3.0.0-beta RegistrationsBaseUrl/3.0.0-rc]
      }.freeze

      SERVICE_COMMENTS = {
        download: 'Get package content (.nupkg).',
        search: 'Filter and search for packages by keyword.',
        publish: 'Push and delete (or unlist) packages.',
        metadata: 'Get package metadata.'
      }.freeze

      VERSION = '3.0.0'.freeze

      def initialize(project)
        @project = project
      end

      def version
        VERSION
      end

      def resources
        [
          build_service(:download),
          build_service(:search),
          build_service(:publish),
          build_service(:metadata)
        ].flatten
      end

      private

      def build_service(service_type)
        url = build_service_url(service_type)
        comment = SERVICE_COMMENTS[service_type]

        SERVICE_VERSIONS[service_type].map do |version|
          { :@id => url, :@type => version, :comment => comment }
        end
      end

      def build_service_url(service_type)
        base_path = api_v4_projects_packages_nuget_path(id: @project.id)

        full_path = case service_type
                    when :download
                      api_v4_projects_packages_nuget_download_package_name_package_version_package_filename_path(
                        {
                          id: @project.id,
                          package_name: nil,
                          package_version: nil,
                          package_filename: nil
                        },
                        true
                      )
                    when :search
                      "#{base_path}/query"
                    when :metadata
                      api_v4_projects_packages_nuget_metadata_package_name_package_version_path(
                        {
                          id: @project.id,
                          package_name: nil,
                          package_version: nil
                        },
                        true
                      )
                    when :publish
                      base_path
                    end

        expose_url(full_path)
      end
    end
  end
end
