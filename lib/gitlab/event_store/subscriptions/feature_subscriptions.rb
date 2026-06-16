# frozen_string_literal: true

module Gitlab
  module EventStore
    module Subscriptions
      class FeatureSubscriptions < BaseSubscriptions
        def register
          # Example: Subscribe a worker to feature flag changes
          # store.subscribe ::YourWorker, to: ::Gitlab::FeatureFlags::FeatureFlagModifiedEvent,
          #   if: ->(event) { event.data[:feature_key] == 'your_feature_flag_name' }
          #
          # To handle specific operations:
          # store.subscribe ::YourWorker, to: ::Gitlab::FeatureFlags::FeatureFlagModifiedEvent,
          #   if: ->(event) do
          #     event.data[:feature_key] == 'your_feature_flag_name' &&
          #     event.data[:operation] == Feature::OPERATION_ENABLED_ACTOR
          #   end
        end
      end
    end
  end
end
