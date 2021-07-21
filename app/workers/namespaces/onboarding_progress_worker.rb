# frozen_string_literal: true

module Namespaces
  class OnboardingProgressWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :product_analytics
    tags :exclude_from_kubernetes
    urgency :low

    deduplicate :until_executed
    idempotent!

    def perform(namespace_id, action)
      namespace = Namespace.find_by_id(namespace_id)
      return unless namespace && action

      OnboardingProgressService.new(namespace).execute(action: action.to_sym)
    end
  end
end
