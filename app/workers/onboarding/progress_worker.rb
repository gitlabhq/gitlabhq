# frozen_string_literal: true

module Onboarding
  class ProgressWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :onboarding
    worker_resource_boundary :cpu
    urgency :low

    deduplicate :until_executed
    idempotent!

    def perform(_namespace_id, _action)
      # Deprecating per guide: https://docs.gitlab.com/ee/development/sidekiq/compatibility_across_updates.html#removing-worker-classes
      # TODO: remove in https://gitlab.com/gitlab-org/gitlab/-/issues/472664
    end
  end
end
