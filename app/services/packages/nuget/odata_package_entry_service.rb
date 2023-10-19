# frozen_string_literal: true

module Packages
  module Nuget
    class OdataPackageEntryService
      include API::Helpers::RelatedResourcesHelpers

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
              <d:Version>#{params[:package_version]}</d:Version>
            </m:properties>
          </entry>
        XML
      end

      def id_url
        expose_url "#{api_v4_projects_packages_nuget_v2_path(id: project.id)}" \
                   "/Packages(Id='#{params[:package_name]}',Version='#{params[:package_version]}')"
      end

      def download_url
        if params[:package_version].present?
          expose_url api_v4_projects_packages_nuget_download_package_name_package_version_package_filename_path(
            {
              id: project.id,
              package_name: params[:package_name],
              package_version: params[:package_version],
              package_filename: file_name
            },
            true
          )
        else
          xml_base
        end
      end

      def xml_base
        expose_url api_v4_projects_packages_nuget_v2_path(id: project.id)
      end

      def file_name
        "#{params[:package_name]}.#{params[:package_version]}.nupkg"
      end
    end
  end
end
