# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class PackageMetadata < Grape::Entity
        expose :json_url, as: :@id, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json' }
        expose :archive_url, as: :packageContent, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg' }
        expose :catalog_entry, as: :catalogEntry, using: ::API::Entities::Nuget::PackageMetadataCatalogEntry,
          documentation: { type: 'API::Entities::Nuget::PackageMetadataCatalogEntry' }
      end
    end
  end
end
