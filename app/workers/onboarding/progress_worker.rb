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

    def perform(namespace_id, action)
      namespace = Namespace.find_by_id(namespace_id)
      return unless namespace && action

      Onboarding::ProgressService.new(namespace).execute(action: action.to_sym)
    end
  end
end

# remove in %15.6 as per https://gitlab.com/gitlab-org/gitlab/-/issues/372432
Namespaces::OnboardingProgressWorker = Onboarding::ProgressWorker
