# frozen_string_literal: true

module API
  module Entities
    module System
      class BroadcastMessage < Grape::Entity
        expose :id, documentation: { type: 'Integer', format: 'int64' }
        expose :message, documentation: { type: 'String', example: 'Example broadcast message' }
        expose :starts_at, documentation: { type: 'DateTime', example: '2016-01-04T15:39:55.570Z' }
        expose :ends_at, documentation: { type: 'DateTime', example: '2016-01-06T15:39:55.570Z' }
        expose :color, documentation: { type: 'String', example: '#E75E40' }
        expose :font, documentation: { type: 'String', example: '#FFFFFF' }
        expose :target_access_levels, documentation: { type: 'Array', items: { type: 'Integer' }, example: [10, 30] }
        expose :target_path, documentation: { type: 'String', example: '*/welcome' }
        expose :broadcast_type, documentation: { type: 'String', example: 'banner' }
        expose :theme, documentation: { type: 'String', example: 'indigo' }
        expose :dismissable, documentation: { type: 'Boolean' }
        expose :active?, as: :active, documentation: { type: 'Boolean' }
      end
    end
  end
end
