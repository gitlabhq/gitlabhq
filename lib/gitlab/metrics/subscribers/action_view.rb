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
          values = values_for(event)
          tags   = tags_for(event)

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
