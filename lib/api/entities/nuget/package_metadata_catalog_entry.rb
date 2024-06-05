# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class PackageMetadataCatalogEntry < Grape::Entity
        expose :json_url, as: :@id, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json' }
        expose :dependency_groups, as: :dependencyGroups, using: ::API::Entities::Nuget::DependencyGroup,
          documentation: { is_array: true, type: 'API::Entities::Nuget::DependencyGroup' }
        expose :package_name, as: :id, documentation: { type: 'string', example: 'MyNuGetPkg' }
        expose :package_version, as: :version, documentation: { type: 'string', example: '1.3.0.17' }
        expose :tags, documentation: { type: 'string', example: 'tag#1 tag#2' }
        expose :archive_url, as: :packageContent, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg' }
        expose :metadatum, using: ::API::Entities::Nuget::Metadatum, merge: true,
          documentation: { type: 'API::Entities::Nuget::Metadatum' }
        expose :published, documentation: { type: 'string', example: '2023-05-08T17:23:25Z' }
      end
    end
  end
end
