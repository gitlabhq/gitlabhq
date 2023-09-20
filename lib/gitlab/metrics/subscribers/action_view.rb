# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the rendering timings of views.
      class ActionView < ActiveSupport::Subscriber
        attach_to :action_view

        SERIES = 'views'

        def render_template(event)
          track(event) if current_transaction
        end

        alias_method :render_view, :render_template

        private

        def track(event)
          tags = tags_for(event)
          current_transaction.observe(:gitlab_view_rendering_duration_seconds, event.duration, tags) do
            docstring 'View rendering time'
            label_keys %i[view]
            buckets [0.001, 0.01, 0.1, 1, 10.0]
            with_feature :prometheus_metrics_view_instrumentation
          end

          current_transaction.increment(:gitlab_transaction_view_duration_total, event.duration)
        end

        def relative_path(path)
          path.gsub(%r{^#{Rails.root}/?}, '')
        end

        def tags_for(event)
          path = relative_path(event.payload[:identifier])

          { view: path }
        end

        def current_transaction
          ::Gitlab::Metrics::WebTransaction.current
        end
      end
    end
  end
end
