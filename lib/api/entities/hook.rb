# frozen_string_literal: true

module API
  module Entities
    class Hook < Grape::Entity
      expose :id, :url, :created_at, :push_events, :tag_push_events, :merge_requests_events, :repository_update_events
      expose :enable_ssl_verification
    end
  end
end
