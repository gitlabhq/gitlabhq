# frozen_string_literal: true

module Onboarding
  class IssueCreatedWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :onboarding
    urgency :low

    deduplicate :until_executing
    idempotent!

    def perform(namespace_id)
      namespace = Namespace.find_by_id(namespace_id)
      return unless namespace

      Onboarding::ProgressService.new(namespace).execute(action: :issue_created)
    end
  end
end
