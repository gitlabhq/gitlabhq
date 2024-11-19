# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      class StatActivitySampler < BaseSampler
        DEFAULT_SAMPLING_INTERVAL_SECONDS = 60

        def sample
          return unless ::Feature.enabled?(:sample_pg_stat_activity, Feature.current_pod, type: :ops)

          Gitlab::Database::StatActivitySampler.sample
        end
      end
    end
  end
end
