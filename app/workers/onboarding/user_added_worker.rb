# frozen_string_literal: true

module Onboarding
  class UserAddedWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :onboarding
    urgency :low

    idempotent!

    def perform(namespace_id)
      namespace = Namespace.find(namespace_id)
      Onboarding::ProgressService.new(namespace).execute(action: :user_added)
    end
  end
end
