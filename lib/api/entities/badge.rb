# frozen_string_literal: true

module API
  module Entities
    class Badge < Entities::BasicBadgeDetails
      expose :id, documentation: { type: 'Integer', format: 'int64', example: 1 }
      expose :kind, documentation: { type: 'String', example: 'project' } do |badge|
        badge.type == 'ProjectBadge' ? 'project' : 'group'
      end
    end
  end
end
