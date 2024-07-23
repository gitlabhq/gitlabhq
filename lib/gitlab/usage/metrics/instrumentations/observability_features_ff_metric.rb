# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ObservabilityFeaturesFfMetric < GenericMetric
          value do
            # rubocop:disable Gitlab/FeatureFlagWithoutActor -- we are checking if the flag is enabled for all groups
            if Feature.enabled?(:observability_features, type: :wip)
              # If the flag is globally enabled, it's enabled for all groups.
              # Querying for Group.count here would not be a performant option,
              # Keeping it as -1 to indicate it is enabled for all.
              -1
              # rubocop:enable Gitlab/FeatureFlagWithoutActor
            else
              Feature.group_ids_for(:observability_features).length
            end
          end
        end
      end
    end
  end
end
