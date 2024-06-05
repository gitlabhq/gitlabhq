# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class SearchResult < Grape::Entity
        expose :type, as: :@type, documentation: { type: 'string', example: 'Package' }
        expose :name, as: :id, documentation: { type: 'string', example: 'MyNuGetPkg' }
        expose :name, as: :title, documentation: { type: 'string', example: 'MyNuGetPkg' }
        expose :total_downloads, as: :totalDownloads, documentation: { type: 'integer', example: 1 }
        expose :verified, documentation: { type: 'boolean' }
        expose :version, documentation: { type: 'string', example: '1.3.0.17' }
        expose :versions, using: ::API::Entities::Nuget::SearchResultVersion
        expose :tags, documentation: { type: 'string', example: 'tag#1 tag#2' }
        expose :metadatum, using: ::API::Entities::Nuget::Metadatum, merge: true,
          documentation: { is_array: true, type: 'API::Entities::Nuget::Metadatum' }
      end
    end
  end
end
