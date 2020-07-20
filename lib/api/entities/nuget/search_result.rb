# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class SearchResult < Grape::Entity
        expose :type, as: :@type
        expose :authors
        expose :name, as: :id
        expose :name, as: :title
        expose :summary
        expose :total_downloads, as: :totalDownloads
        expose :verified
        expose :version
        expose :versions, using: ::API::Entities::Nuget::SearchResultVersion
        expose :tags
        expose :metadatum, using: ::API::Entities::Nuget::Metadatum, merge: true
      end
    end
  end
end
