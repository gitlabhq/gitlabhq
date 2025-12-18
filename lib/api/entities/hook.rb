# frozen_string_literal: true

module API
  module Entities
    class Hook < Grape::Entity
      expose :id, documentation: { type: 'String', example: 1 }
      expose :url, documentation: { type: 'String', example: 'https://webhook.site' }
      expose :name, documentation: { type: 'String', example: 'Hook name' }
      expose :description, documentation: { type: 'String', example: 'Hook description' }
      expose :created_at, documentation: { type: 'DateTime', example: '2012-05-28T04:42:42-07:00' }
      expose :push_events, documentation: { type: 'Boolean' }
      expose :tag_push_events, documentation: { type: 'Boolean' }
      expose :merge_requests_events, documentation: { type: 'Boolean' }
      expose :repository_update_events, documentation: { type: 'Boolean' }
      expose :enable_ssl_verification, documentation: { type: 'Boolean' }
      expose :organization_id,
        if: ->(hook, _) { hook.is_a?(SystemHook) },
        documentation: { type: 'Integer', example: 1 }

      expose :alert_status, documentation: { type: 'Symbol', example: :executable }
      expose :disabled_until, documentation: { type: 'DateTime', example: '2012-05-28T04:42:42-07:00' }
      expose :url_variables,
        if: ->(_, options) { options[:with_url_variables] != false },
        documentation: { type: 'Hash', example: { "token" => "secr3t" }, is_array: true }
      expose :push_events_branch_filter, documentation: { type: 'String', example: 'my-branch-*' }
      expose :branch_filter_strategy, documentation: { type: 'String', example: 'wildcard' }

      expose :custom_webhook_template, documentation: { type: 'String', example: '{"event":"{{object_kind}}"}' }
      expose :custom_headers,
        if: ->(_, options) { options[:with_custom_headers] != false },
        documentation: { type: 'Hash', example: { "X-Custom-Header" => "value" }, is_array: true }

      def url_variables
        object.masked_url_variables
      end

      def custom_headers
        object.masked_custom_headers
      end
    end
  end
end
