# frozen_string_literal: true

module Gitlab
  module EventStore
    module Subscriptions
      class FeatureSubscriptions < BaseSubscriptions
        def register
          store.subscribe ::Organizations::RootGroupOrganizationBackfillWorker,
            to: ::Gitlab::FeatureFlags::FeatureFlagModifiedEvent,
            if: ->(event) { event.data[:feature_key] == 'root_group_organization_backfill' }

          store.subscribe ::Organizations::ConfirmWorker,
            to: ::Gitlab::FeatureFlags::FeatureFlagModifiedEvent,
            if: ->(event) { event.data[:feature_key] == 'root_group_organization_confirm' }
        end
      end
    end
  end
end
