module Projects
  module CycleAnalytics
    class EventsController < Projects::ApplicationController
      include CycleAnalyticsParams

      before_action :authorize_read_cycle_analytics!
      before_action :authorize_read_build!, only: [:test, :staging]
      before_action :authorize_read_issue!, only: [:issue, :production]
      before_action :authorize_read_merge_request!, only: [:code, :review]

      def issue
        render_events(cycle_analytics[:issue].events)
      end

      def plan
        render_events(cycle_analytics[:plan].events)
      end

      def code
        render_events(cycle_analytics[:code].events)
      end

      def test
        options(events_params)[:branch] = events_params[:branch_name]

        render_events(cycle_analytics[:test].events)
      end

      def review
        render_events(cycle_analytics[:review].events)
      end

      def staging
        render_events(cycle_analytics[:staging].events)
      end

      def production
        render_events(cycle_analytics[:production].events)
      end

      private

      def render_events(events)
        respond_to do |format|
          format.html
          format.json { render json: { events: events } }
        end
      end

      def cycle_analytics
        @cycle_analytics ||= ::CycleAnalytics.new(project, options(events_params))
      end

      def events_params
        return {} unless params[:events].present?

        params[:events].permit(:start_date, :branch_name)
      end
    end
  end
end
