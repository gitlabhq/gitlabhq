# frozen_string_literal: true

module API
  module Entities
    class MobilePushSubscription < Grape::Entity
      expose :id, documentation: { type: 'Integer', format: 'int64', example: 1 }
      expose :created_at, documentation: { type: 'DateTime', example: '2026-07-30T12:00:00.000Z' }
    end
  end
end
