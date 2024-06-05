# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class PackagesMetadataItem < Grape::Entity
        expose :json_url, as: :@id, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json' }
        expose :lower_version, as: :lower, documentation: { type: 'string', example: '1.3.0.17' }
        expose :upper_version, as: :upper, documentation: { type: 'string', example: '1.3.0.17' }
        expose :packages_count, as: :count, documentation: { type: 'integer', example: 1 }
        expose :packages, as: :items, using: ::API::Entities::Nuget::PackageMetadata,
          documentation: { is_array: true, type: 'API::Entities::Nuget::PackageMetadata' }
      end
    end
  end
end
