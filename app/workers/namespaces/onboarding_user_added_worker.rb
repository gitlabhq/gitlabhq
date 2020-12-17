# frozen_string_literal: true

module Namespaces
  class OnboardingUserAddedWorker
    include ApplicationWorker

    feature_category :users
    urgency :low

    idempotent!

    def perform(namespace_id)
      namespace = Namespace.find(namespace_id)
      OnboardingProgressService.new(namespace).execute(action: :user_added)
    end
  end
end
