class Groups::AnalyticsController < Groups::ApplicationController
  before_action :group

  layout 'group'

  def show
    @users = @group.users
    @start_date = params[:start_date] || Date.today - 1.week
    @events = Event.contributions.
      where("created_at > ?", @start_date).
      where(project_id: @group.projects)

    @stats = {}

    @stats[:merge_requests] = @users.map do |user|
      @events.merge_requests.created.where(author_id: user).count
    end

    @stats[:issues] = @users.map do |user|
      @events.issues.closed.where(author_id: user).count
    end

    @stats[:push] = @users.map do |user|
      @events.code_push.where(author_id: user).count
    end
  end
end
