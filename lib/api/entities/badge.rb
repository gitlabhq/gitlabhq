# frozen_string_literal: true

module API
  module Entities
    class Badge < Entities::BasicBadgeDetails
      expose :id
      expose :kind do |badge|
        badge.type == 'ProjectBadge' ? 'project' : 'group'
      end
    end
  end
end
