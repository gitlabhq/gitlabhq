# frozen_string_literal: true

module API
  module Entities
    class WebHookLog < Grape::Entity
      expose :id, documentation: { type: 'string', example: 1 }
      expose :url, documentation: { type: 'string', example: 'https://example.com' }
      expose :trigger, documentation: { type: 'string', example: 'push_hooks' }
      expose :request_headers, documentation: { type: 'Hash', example: { 'Content-Type' => 'application/json' } }
      expose :request_data, documentation: { type: 'Hash', example: { 'user_id' => 72, 'event_name' => 'push' } }
      expose :response_headers, documentation: { type: 'Hash', example: { 'Content-Type' => 'application/json' } }
      expose :response_body, documentation: { type: 'string', example: '"{\"success\":true}"' }
      expose :execution_duration, documentation: { type: 'number', format: 'float', example: 98.29 }
      expose :response_status, documentation: { type: 'string', example: '200' }
      expose :created_at, documentation: { type: 'dateTime', example: '2012-05-28T04:42:42-07:00' }
    end
  end
end
