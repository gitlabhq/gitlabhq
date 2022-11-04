# frozen_string_literal: true

module API
  module Entities
    module Ci
      class ResourceGroup < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 1 }
        expose :key, documentation: { type: 'string', example: 'production' }
        expose :process_mode, documentation: { type: 'string', example: 'unordered' }
        expose :created_at, documentation: { type: 'dateTime', example: '2021-09-01T08:04:59.650Z' }
        expose :updated_at, documentation: { type: 'dateTime', example: '2021-09-01T08:04:59.650Z' }
      end
    end
  end
end
