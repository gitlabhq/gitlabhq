# frozen_string_literal: true

module Projects
  module CycleAnalytics
    class EventsController < Projects::ApplicationController
      include CycleAnalyticsParams
      include GracefulTimeoutHandling

      before_action :authorize_read_cycle_analytics!
      before_action :authorize_read_build!, only: [:test, :staging]
      before_action :authorize_read_issue!, only: [:issue, :production]
      before_action :authorize_read_merge_request!, only: [:code, :review]

      feature_category :planning_analytics

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
        options(cycle_analytics_project_params)[:branch] = cycle_analytics_project_params[:branch_name]

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
        @cycle_analytics ||= ::Analytics::CycleAnalytics::ProjectLevel.new(project: project, options: options(cycle_analytics_project_params))
      end
    end
  end
end
