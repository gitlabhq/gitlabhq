# frozen_string_literal: true

module API
  module Entities
    class RetryWebhookEvent < Grape::Entity
      expose :response_status, documentation: { type: 'integer', example: 200 } do |event|
        event.payload[:http_status]
      end
    end
  end
end
