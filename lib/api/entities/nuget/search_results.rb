# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class SearchResults < Grape::Entity
        expose :total_count, as: :totalHits, documentation: { type: 'integer', example: 1 }
        expose :data, using: ::API::Entities::Nuget::SearchResult,
          documentation: { is_array: true, type: 'API::Entities::Nuget::SearchResult' }
      end
    end
  end
end
