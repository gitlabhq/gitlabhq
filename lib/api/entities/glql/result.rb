# frozen_string_literal: true

module API
  module Entities
    module Glql
      class Result < Grape::Entity
        expose :data, using: ::API::Entities::Glql::Data,
          documentation: { type: 'object', desc: 'Query result data containing count, nodes, and pagination info' }
        expose :error,
          documentation: { type: 'String', desc: 'Error message if query failed' }
        expose :fields, using: ::API::Entities::Glql::Field,
          documentation: { type: 'array', is_array: true, desc: 'Field definitions for the query results' }
        expose :success, documentation: { type: 'Boolean', example: true }
      end
    end
  end
end
