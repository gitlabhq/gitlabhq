# frozen_string_literal: true

module Onboarding
  class PipelineCreatedWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :onboarding
    urgency :low

    deduplicate :until_executing
    idempotent!

    def perform(_namespace_id)
      # Deprecating per guide: https://docs.gitlab.com/ee/development/sidekiq/compatibility_across_updates.html#removing-worker-classes
      # TODO: cleanup in https://gitlab.com/gitlab-org/gitlab/-/issues/472664
    end
  end
end
