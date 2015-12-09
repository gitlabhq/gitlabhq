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
          path   = relative_path(event.payload[:identifier])
          values = values_for(event)

          current_transaction.add_metric(SERIES, values, path: path)
        end

        def relative_path(path)
          path.gsub(/^#{Rails.root.to_s}\/?/, '')
        end

        def values_for(event)
          values = { duration: event.duration }

          file, line = Metrics.last_relative_application_frame

          if file and line
            values[:file] = file
            values[:line] = line
          end

          values
        end

        def current_transaction
          Transaction.current
        end
      end
    end
  end
end
