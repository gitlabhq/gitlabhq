# frozen_string_literal: true

module Gitlab
  module Metrics
    module Labkit
      extend ActiveSupport::Concern

      class_methods do
        def client
          ::Labkit::Metrics::Client
        end
        alias_method :registry, :client

        def null_metric
          ::Labkit::Metrics::Null.instance
        end

        def error?
          !client.enabled?
        end

        # TODO: remove when we move away from Prometheus::Client to Labkit::Metrics::Client completely
        # https://gitlab.com/gitlab-com/gl-infra/observability/team/-/issues/4160.
        #
        # This method is kept here for compatibility with the old implementation only:
        # lib/gitlab/metrics/prometheus.rb. This is a implementation detail supposed
        # to be hidden within Labkit::Metrics::Client.enabled?/disabled? methods.
        def metrics_folder_present?
          client.enabled?
        end

        # Used only in specs to reset the error state
        #
        # TODO: remove when we move away from Prometheus::Client to Labkit::Metrics::Client completely
        # https://gitlab.com/gitlab-com/gl-infra/observability/team/-/issues/4160
        def reset_registry!
          @prometheus_metrics_enabled = nil
          client.reset!
        end

        def counter(name, docstring, base_labels = {})
          safe_provide_metric(:counter, name, docstring, base_labels)
        end

        def summary(name, docstring, base_labels = {})
          safe_provide_metric(:summary, name, docstring, base_labels)
        end

        def gauge(name, docstring, base_labels = {}, multiprocess_mode = :all)
          safe_provide_metric(:gauge, name, docstring, base_labels, multiprocess_mode)
        end

        def histogram(name, docstring, base_labels = {}, buckets = ::Prometheus::Client::Histogram::DEFAULT_BUCKETS)
          safe_provide_metric(:histogram, name, docstring, base_labels, buckets)
        end

        # TODO: remove when we move away from Prometheus::Client to Labkit::Metrics::Client completely
        # https://gitlab.com/gitlab-com/gl-infra/observability/team/-/issues/4160
        def error_detected!
          @prometheus_metrics_enabled = nil

          client.disable!
        end

        # Used only in specs to reset the error state
        #
        # TODO: remove when we move away from Prometheus::Client to Labkit::Metrics::Client completely
        # https://gitlab.com/gitlab-com/gl-infra/observability/team/-/issues/4160
        def clear_errors!
          @prometheus_metrics_enabled = nil

          client.enable!
        end

        def prometheus_metrics_enabled?
          prometheus_metrics_enabled_memoized
        end

        private

        # TODO: remove when we move away from Prometheus::Client to Labkit::Metrics::Client completely
        # https://gitlab.com/gitlab-com/gl-infra/observability/team/-/issues/4160
        def safe_provide_metric(metric_type, metric_name, *args)
          return null_metric unless prometheus_metrics_enabled?

          client.send(metric_type, metric_name, *args) # rubocop:disable GitlabSecurity/PublicSend -- temporary workaround, see issue link
        end

        def prometheus_metrics_enabled_memoized
          @prometheus_metrics_enabled ||=
            (client.enabled? && Gitlab::CurrentSettings.prometheus_metrics_enabled) || false
        end
      end
    end
  end
end
