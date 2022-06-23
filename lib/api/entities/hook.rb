# frozen_string_literal: true

module API
  module Entities
    class Hook < Grape::Entity
      expose :id, :url, :created_at, :push_events, :tag_push_events, :merge_requests_events, :repository_update_events
      expose :enable_ssl_verification

      expose :alert_status
      expose :disabled_until
      expose :url_variables

      def url_variables
        object.url_variables.keys.map { { key: _1 } }
      end
    end
  end
end
