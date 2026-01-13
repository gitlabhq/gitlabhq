# frozen_string_literal: true

module API
  module Entities
    module Ci
      class ResourceGroup < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :key, documentation: { type: 'String', example: 'production' }
        expose :process_mode, documentation: { type: 'String', example: 'unordered' }
        expose :created_at, documentation: { type: 'DateTime', example: '2021-09-01T08:04:59.650Z' }
        expose :updated_at, documentation: { type: 'DateTime', example: '2021-09-01T08:04:59.650Z' }
      end
    end
  end
end
