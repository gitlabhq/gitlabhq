# frozen_string_literal: true

module Packages
  module Nuget
    module V2
      class MetadataIndexPresenter
        def xml
          Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            xml['edmx'].Edmx('xmlns:edmx' => 'http://schemas.microsoft.com/ado/2007/06/edmx', Version: '1.0') do
              xml['edmx'].DataServices('xmlns:m' => 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata',
                'm:DataServiceVersion' => '2.0', 'm:MaxDataServiceVersion' => '2.0') do
                xml.Schema(xmlns: 'http://schemas.microsoft.com/ado/2006/04/edm', Namespace: 'NuGetGallery.OData') do
                  xml.EntityType(Name: 'V2FeedPackage', 'm:HasStream' => true) do
                    xml.Key do
                      xml.PropertyRef(Name: 'Id')
                      xml.PropertyRef(Name: 'Version')
                    end
                    xml.Property(Name: 'Id', Type: 'Edm.String', Nullable: false)
                    xml.Property(Name: 'Version', Type: 'Edm.String', Nullable: false)
                    xml.Property(Name: 'Authors', Type: 'Edm.String')
                    xml.Property(Name: 'Dependencies', Type: 'Edm.String')
                    xml.Property(Name: 'Description', Type: 'Edm.String')
                    xml.Property(Name: 'DownloadCount', Type: 'Edm.Int64', Nullable: false)
                    xml.Property(Name: 'IconUrl', Type: 'Edm.String')
                    xml.Property(Name: 'Published', Type: 'Edm.DateTime', Nullable: false)
                    xml.Property(Name: 'ProjectUrl', Type: 'Edm.String')
                    xml.Property(Name: 'Tags', Type: 'Edm.String')
                    xml.Property(Name: 'Title', Type: 'Edm.String')
                    xml.Property(Name: 'LicenseUrl', Type: 'Edm.String')
                  end
                end
                xml.Schema(xmlns: 'http://schemas.microsoft.com/ado/2006/04/edm', Namespace: 'NuGetGallery') do
                  xml.EntityContainer(Name: 'V2FeedContext', 'm:IsDefaultEntityContainer' => true) do
                    xml.EntitySet(Name: 'Packages', EntityType: 'NuGetGallery.OData.V2FeedPackage')
                    xml.FunctionImport(Name: 'FindPackagesById',
                      ReturnType: 'Collection(NuGetGallery.OData.V2FeedPackage)', EntitySet: 'Packages') do
                      xml.Parameter(Name: 'id', Type: 'Edm.String', FixedLength: 'false', Unicode: 'false')
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
