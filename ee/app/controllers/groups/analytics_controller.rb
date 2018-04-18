class Groups::AnalyticsController < Groups::ApplicationController
  before_action :group
  before_action :check_contribution_analytics_available!
  before_action :load_events

  layout 'group'

  def show
    respond_to do |format|
      format.html do
        @stats = {}
        @stats[:push] = count_by_user(event_totals[:push])
        @stats[:merge_requests_created] = count_by_user(event_totals[:merge_requests_created])
        @stats[:issues_closed] = count_by_user(event_totals[:issues_closed])
      end

      format.json do
        render json: GroupAnalyticsSerializer
                 .new(events: event_totals)
                 .represent(users), status: 200
      end
    end
  end

  private

  def count_by_user(data)
    users.map { |user| data.fetch(user.id, 0) }
  end

  def users
    @users ||= @group.users.select(:id, :name, :username).reorder(:id)
  end

  def load_events
    @start_date = params[:start_date] || Date.today - 1.week
    @events = Event.contributions
                .where("created_at > ?", @start_date)
                .where(project_id: @group.projects)
  end

  def event_totals
    @event_totals ||= {
      push: @events.code_push.totals_by_author,
      issues_created: @events.issues.created.totals_by_author,
      issues_closed: @events.issues.closed.totals_by_author,
      merge_requests_created: @events.merge_requests.created.totals_by_author,
      merge_requests_merged: @events.merge_requests.merged.totals_by_author,
      total_events: @events.totals_by_author
    }
  end

  def check_contribution_analytics_available!
    render_404 unless @group.feature_available?(:contribution_analytics) || LicenseHelper.show_promotions?(current_user)
  end
end
