# frozen_string_literal: true

class BuildFinishedWorker < ::Ci::BuildFinishedWorker # rubocop:disable Scalability/IdempotentWorker
  # DEPRECATED: Not triggered since https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64934/

  # We need to explicitly specify these settings. They aren't inheriting from the parent class.
  urgency :high
  worker_resource_boundary :cpu
end
