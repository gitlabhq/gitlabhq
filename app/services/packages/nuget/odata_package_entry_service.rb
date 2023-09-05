# frozen_string_literal: true

module Packages
  module Nuget
    class OdataPackageEntryService
      include API::Helpers::RelatedResourcesHelpers

      SEMVER_LATEST_VERSION_PLACEHOLDER = '0.0.0-latest-version'
      LATEST_VERSION_FOR_V2_DOWNLOAD_ENDPOINT = 'latest'

      def initialize(project, params)
        @project = project
        @params = params
      end

      def execute
        ServiceResponse.success(payload: package_entry)
      end

      private

      attr_reader :project, :params

      def package_entry
        <<-XML.squish
          <entry xmlns='http://www.w3.org/2005/Atom' xmlns:d='http://schemas.microsoft.com/ado/2007/08/dataservices' xmlns:georss='http://www.georss.org/georss' xmlns:gml='http://www.opengis.net/gml' xmlns:m='http://schemas.microsoft.com/ado/2007/08/dataservices/metadata' xml:base="#{xml_base}">
            <id>#{id_url}</id>
            <category term='V2FeedPackage' scheme='http://schemas.microsoft.com/ado/2007/08/dataservices/scheme'/>
            <title type='text'>#{params[:package_name]}</title>
            <content type='application/zip' src="#{download_url}"/>
            <m:properties>
              <d:Version>#{package_version}</d:Version>
            </m:properties>
          </entry>
        XML
      end

      def package_version
        params[:package_version] || SEMVER_LATEST_VERSION_PLACEHOLDER
      end

      def id_url
        expose_url "#{api_v4_projects_packages_nuget_v2_path(id: project.id)}" \
                   "/Packages(Id='#{params[:package_name]}',Version='#{package_version}')"
      end

      # TODO: use path helper when download endpoint is merged
      def download_url
        expose_url "#{api_v4_projects_packages_nuget_v2_path(id: project.id)}" \
                   "/download/#{params[:package_name]}/#{download_url_package_version}"
      end

      def download_url_package_version
        if latest_version?
          LATEST_VERSION_FOR_V2_DOWNLOAD_ENDPOINT
        else
          params[:package_version]
        end
      end

      def latest_version?
        params[:package_version].nil? || params[:package_version] == SEMVER_LATEST_VERSION_PLACEHOLDER
      end

      def xml_base
        expose_url api_v4_projects_packages_nuget_v2_path(id: project.id)
      end
    end
  end
end
