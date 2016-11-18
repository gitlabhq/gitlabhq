module Projects
  module CycleAnalytics
    class EventsController < Projects::ApplicationController
      include CycleAnalyticsParams
    
      before_action :authorize_read_cycle_analytics!
      before_action :authorize_builds!, only: [:test, :staging]
      before_action :authorize_read_issue!, only: [:issue, :production]
      before_action :authorize_read_merge_request!, only: [:code, :review]

      def issue
        render_events(events.issue_events)
      end
    
      def plan
        render_events(events.plan_events)
      end
    
      def code
        render_events(events.code_events)
      end
    
      def test
        options[:branch] = events_params[:branch_name]
    
        render_events(events.test_events)
      end
    
      def review
        render_events(events.review_events)
      end
    
      def staging
        render_events(events.staging_events)
      end
    
      def production
        render_events(events.production_events)
      end
    
      private
    
      def render_events(events_list)
        respond_to do |format|
          format.html
          format.json { render json: { events: events_list } }
        end
      end
    
      def events
        @events ||= Gitlab::CycleAnalytics::Events.new(project: project, options: options)
      end
    
      def options
        @options ||= { from: start_date(events_params), current_user: current_user }
      end
    
      def events_params
        return {} unless params[:events].present?
    
        params[:events].slice(:start_date, :branch_name)
      end
    
      def authorize_builds!
        return access_denied! unless can?(current_user, :read_build, project)
      end

      def authorize_read_issue!
        return access_denied! unless can?(current_user, :read_issue, project)
      end
    end
  end
end
