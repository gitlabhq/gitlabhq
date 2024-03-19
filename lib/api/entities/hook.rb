# frozen_string_literal: true

module API
  module Entities
    class Hook < Grape::Entity
      expose :id, documentation: { type: 'string', example: 1 }
      expose :url, documentation: { type: 'string', example: 'https://webhook.site' }
      expose :created_at, documentation: { type: 'dateTime', example: '2012-05-28T04:42:42-07:00' }
      expose :push_events, documentation: { type: 'boolean' }
      expose :tag_push_events, documentation: { type: 'boolean' }
      expose :merge_requests_events, documentation: { type: 'boolean' }
      expose :repository_update_events, documentation: { type: 'boolean' }
      expose :enable_ssl_verification, documentation: { type: 'boolean' }

      expose :alert_status, documentation: { type: 'symbol', example: :executable }
      expose :disabled_until, documentation: { type: 'dateTime', example: '2012-05-28T04:42:42-07:00' }
      expose :url_variables,
        if: ->(_, options) { options[:with_url_variables] != false },
        documentation: { type: 'Hash', example: { "token" => "secr3t" }, is_array: true }

      expose :custom_webhook_template, documentation: { type: 'string', example: '{"event":"{{object_kind}}"}' }

      def url_variables
        object.url_variables.keys.map { { key: _1 } }
      end
    end
  end
end
