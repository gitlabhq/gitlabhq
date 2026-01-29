# frozen_string_literal: true

module API
  module Entities
    module Glql
      class Data < Grape::Entity
        expose :count, documentation: { type: 'Integer', example: 42, desc: 'Number of found items' }
        expose :nodes, documentation: { type: 'Array', is_array: true, example: [], desc: 'The list of found items' }
        expose :pageInfo, using: ::API::Entities::Glql::PageInfo,
          documentation: { type: 'object', desc: 'Pagination information' }
      end
    end
  end
end
