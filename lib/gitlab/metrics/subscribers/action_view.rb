module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the rendering timings of views.
      class ActionView < ActiveSupport::Subscriber
        include Gitlab::Metrics::Concern
        histogram :gitlab_view_rendering_duration_seconds, 'View rendering time',
                  base_labels: Transaction::BASE_LABELS.merge({ path: nil }),
                  buckets: [0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.500, 2.0, 10.0]

        attach_to :action_view

        SERIES = 'views'.freeze

        def render_template(event)
          track(event) if current_transaction
        end

        alias_method :render_view, :render_template

        private

        def track(event)
          values = values_for(event)
          tags   = tags_for(event)

          gitlab_view_rendering_duration_seconds.observe(current_transaction.labels.merge(tags), event.duration)

          current_transaction.increment(:view_duration, event.duration)
          current_transaction.add_metric(SERIES, values, tags)
        end

        def relative_path(path)
          path.gsub(/^#{Rails.root.to_s}\/?/, '')
        end

        def values_for(event)
          { duration: event.duration }
        end

        def tags_for(event)
          path = relative_path(event.payload[:identifier])

          { view: path }
        end

        def current_transaction
          Transaction.current
        end
      end
    end
  end
end
