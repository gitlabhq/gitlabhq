# frozen_string_literal: true

module Gitlab
  module WebHooks
    GITLAB_EVENT_HEADER = 'X-Gitlab-Event'
    GITLAB_INSTANCE_HEADER = 'X-Gitlab-Instance'
    GITLAB_UUID_HEADER = 'X-Gitlab-Webhook-UUID'
  end
end
