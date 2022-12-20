# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class ServiceIndex < Grape::Entity
        expose :version, documentation: { type: 'string', example: '1.3.0.17' }
        expose :resources, documentation: { type: 'object', is_array: true, example: '{ "@id": "https://gitlab.com/api/v4/projects/1/packages/nuget/query", "@type": "SearchQueryService", "comment": "Filter and search for packages by keyword."}' }
      end
    end
  end
end
