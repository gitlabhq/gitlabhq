# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class SearchResultVersion < Grape::Entity
        expose :json_url, as: :@id
        expose :version
        expose :downloads
      end
    end
  end
end
