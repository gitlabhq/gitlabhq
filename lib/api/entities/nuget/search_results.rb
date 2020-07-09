# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class SearchResults < Grape::Entity
        expose :total_count, as: :totalHits
        expose :data, using: ::API::Entities::Nuget::SearchResult
      end
    end
  end
end
