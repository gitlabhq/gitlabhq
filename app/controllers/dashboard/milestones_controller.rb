class Dashboard::MilestonesController < Dashboard::ApplicationController
  before_action :load_projects

  def index
    project_milestones = case params[:state]
                         when 'all'; state
                         when 'closed'; state('closed')
                         else state('active')
                         end
    @dashboard_milestones = Milestones::GroupService.new(project_milestones).execute
    @dashboard_milestones = Kaminari.paginate_array(@dashboard_milestones).page(params[:page]).per(PER_PAGE)
  end

  def show
    project_milestones = Milestone.where(project_id: @projects).order("due_date ASC")
    @dashboard_milestone = Milestones::GroupService.new(project_milestones).milestone(title)
  end

  private

  def load_projects
    @projects = current_user.authorized_projects.sorted_by_activity.non_archived
  end

  def title
    params[:title]
  end

  def state(state = nil)
    conditions = { project_id: @projects }
    conditions.reverse_merge!(state: state) if state
    Milestone.where(conditions).order("title ASC")
  end
end
