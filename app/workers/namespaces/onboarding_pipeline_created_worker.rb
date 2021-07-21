# frozen_string_literal: true

module Namespaces
  class OnboardingPipelineCreatedWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :subgroups
    tags :exclude_from_kubernetes
    urgency :low

    deduplicate :until_executing
    idempotent!

    def perform(namespace_id)
      namespace = Namespace.find_by_id(namespace_id)
      return unless namespace

      OnboardingProgressService.new(namespace).execute(action: :pipeline_created)
    end
  end
end
