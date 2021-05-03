# frozen_string_literal: true

module Namespaces
  class OnboardingIssueCreatedWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    feature_category :issue_tracking
    tags :exclude_from_kubernetes
    urgency :low

    deduplicate :until_executing
    idempotent!

    def perform(namespace_id)
      namespace = Namespace.find_by_id(namespace_id)
      return unless namespace

      OnboardingProgressService.new(namespace).execute(action: :issue_created)
    end
  end
end
