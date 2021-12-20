# rubocop:disable Naming/FileName
# frozen_string_literal: true

# We need to supply this outside of Rails because:
# RubySampler needs Gitlab::Metrics needs Gitlab::Metrics::Prometheus needs Gitlab::CurrentSettings needs ::Settings
# to check for `prometheus_metrics_enabled`. We therefore simply redirect it to our own Settings type.
module Gitlab
  module CurrentSettings
    class << self
      def prometheus_metrics_enabled
        # We make the simplified assumption that when the metrics-server runs,
        # Prometheus metrics are enabled. Since the latter is a setting stored
        # in the application database, we have no access to it here, so we need
        # to hard-code it.
        true
      end
    end
  end
end

# rubocop:enable Naming/FileName
