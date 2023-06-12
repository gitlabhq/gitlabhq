# frozen_string_literal: true

module Packages
  module Nuget
    class ServiceIndexPresenter
      include API::Helpers::RelatedResourcesHelpers

      SERVICE_VERSIONS = {
        download: %w[PackageBaseAddress/3.0.0],
        search: %w[SearchQueryService SearchQueryService/3.0.0-beta SearchQueryService/3.0.0-rc],
        symbol: %w[SymbolPackagePublish/4.9.0],
        publish: %w[PackagePublish/2.0.0],
        metadata: %w[RegistrationsBaseUrl RegistrationsBaseUrl/3.0.0-beta RegistrationsBaseUrl/3.0.0-rc]
      }.freeze

      SERVICE_COMMENTS = {
        download: 'Get package content (.nupkg).',
        search: 'Filter and search for packages by keyword.',
        symbol: 'Push symbol packages.',
        publish: 'Push and delete (or unlist) packages.',
        metadata: 'Get package metadata.'
      }.freeze

      VERSION = '3.0.0'

      PROJECT_LEVEL_SERVICES = %i[download publish symbol].freeze
      GROUP_LEVEL_SERVICES = %i[search metadata].freeze

      def initialize(project_or_group)
        @project_or_group = project_or_group
      end

      def version
        VERSION
      end

      def resources
        available_services.flat_map { |service| build_service(service) }
      end

      private

      attr_reader :project_or_group

      def available_services
        case scope
        when :group
          GROUP_LEVEL_SERVICES
        when :project
          (GROUP_LEVEL_SERVICES + PROJECT_LEVEL_SERVICES).flatten
        end
      end

      def build_service(service_type)
        url = build_service_url(service_type)
        comment = SERVICE_COMMENTS[service_type]

        SERVICE_VERSIONS[service_type].map do |version|
          { :@id => url, :@type => version, :comment => comment }
        end
      end

      def build_service_url(service_type)
        full_path = case service_type
                    when :download
                      download_service_url
                    when :search
                      search_service_url
                    when :symbol
                      symbol_service_url
                    when :metadata
                      metadata_service_url
                    when :publish
                      publish_service_url
                    end

        expose_url(full_path)
      end

      def scope
        return :project if project_or_group.is_a?(::Project)
        return :group if project_or_group.is_a?(::Group)
      end

      def download_service_url
        params = {
          id: project_or_group.id,
          package_name: nil,
          package_version: nil,
          package_filename: nil
        }

        api_v4_projects_packages_nuget_download_package_name_package_version_package_filename_path(
          params,
          true
        )
      end

      def metadata_service_url
        params = {
          id: project_or_group.id,
          package_name: nil,
          package_version: nil
        }

        case scope
        when :group
          api_v4_groups___packages_nuget_metadata_package_name_package_version_path(
            params,
            true
          )
        when :project
          api_v4_projects_packages_nuget_metadata_package_name_package_version_path(
            params,
            true
          )
        end
      end

      def search_service_url
        case scope
        when :group
          api_v4_groups___packages_nuget_query_path(id: project_or_group.id)
        when :project
          api_v4_projects_packages_nuget_query_path(id: project_or_group.id)
        end
      end

      def publish_service_url
        api_v4_projects_packages_nuget_path(id: project_or_group.id)
      end

      def symbol_service_url
        api_v4_projects_packages_nuget_symbolpackage_path(id: project_or_group.id)
      end
    end
  end
end
