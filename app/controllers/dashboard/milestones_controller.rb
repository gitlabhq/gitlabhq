class Dashboard::MilestonesController < Dashboard::ApplicationController
  include MilestoneActions

  before_action :projects
  before_action :milestone, only: [:show, :merge_requests, :participants, :labels]

  def index
    respond_to do |format|
      format.html do
        @milestone_states = GlobalMilestone.states_count(@projects)
        @milestones = Kaminari.paginate_array(milestones).page(params[:page])
      end
      format.json do
        render json: milestones
      end
    end
  end

  def show
  end

  private

  def milestones
    group_milestones = MilestonesFinder.new(
      group_ids: current_user.groups.pluck(:id)
    ).execute

    project_milestones = DashboardMilestone.build_collection(@projects, params)

    @milestones = (project_milestones + group_milestones)
  end

  def milestone
    @milestone = DashboardMilestone.build(@projects, params[:title])
    render_404 unless @milestone
  end
end
