class DashboardController < Dashboard::ApplicationController
  include IssuesAction
  include MergeRequestsAction

  before_action :event_filter, only: :activity
  before_action :projects, only: [:issues, :merge_requests, :labels, :milestones]

  respond_to :html

  def activity
    @last_push = current_user.recent_push

    respond_to do |format|
      format.html

      format.json do
        load_events
        pager_json("events/_events", @events.count)
      end
    end
  end

  def labels
    labels = Label.where(project_id: @projects).select(:title, :color).uniq(:title)

    respond_to do |format|
      format.json do
        render json: labels
      end
    end
  end

  def milestones
    milestones = Milestone.where(project_id: @projects).active
    epoch = DateTime.parse('1970-01-01')
    grouped_milestones = GlobalMilestone.build_collection(milestones)
    grouped_milestones = grouped_milestones.sort_by { |x| x.due_date.nil? ? epoch : x.due_date }

    respond_to do |format|
      format.json do
        render json: grouped_milestones
      end
    end
  end

  protected

  def load_events
    projects =
      if params[:filter] == "starred"
        current_user.starred_projects
      else
        current_user.authorized_projects
      end

    @events = Event.in_projects(projects)
    @events = @event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end

  def projects
    @projects ||= current_user.authorized_projects.sorted_by_activity.non_archived
  end
end
