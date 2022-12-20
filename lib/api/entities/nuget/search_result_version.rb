# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class SearchResultVersion < Grape::Entity
        expose :json_url, as: :@id, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json' }
        expose :version, documentation: { type: 'string', example: '1.3.0.17' }
        expose :downloads, documentation: { type: 'integer', example: 1 }
      end
    end
  end
end
