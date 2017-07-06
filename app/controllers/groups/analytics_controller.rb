class Groups::AnalyticsController < Groups::ApplicationController
  before_action :group
  before_action :check_contribution_analytics_available!

  layout 'group'

  def show
    @users = @group.users.select(:id, :name, :username)
    @start_date = params[:start_date] || Date.today - 1.week
    @events = Event.contributions
      .where("created_at > ?", @start_date)
      .where(project_id: @group.projects)

    @stats = {}

    @stats[:total_events] = count_by_user(@events.totals_by_author)
    @stats[:push] = count_by_user(@events.code_push.totals_by_author)
    @stats[:merge_requests_created] = count_by_user(@events.merge_requests.created.totals_by_author)
    @stats[:merge_requests_merged] = count_by_user(@events.merge_requests.merged.totals_by_author)
    @stats[:issues_created] = count_by_user(@events.issues.created.totals_by_author)
    @stats[:issues_closed] = count_by_user(@events.issues.closed.totals_by_author)
  end

  private

  def count_by_user(data)
    user_ids.map { |id| data.fetch(id, 0) }
  end

  def user_ids
    @user_ids ||= @users.map(&:id)
  end
end
