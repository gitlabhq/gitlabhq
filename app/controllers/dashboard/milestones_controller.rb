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

  def group_milestones
    groups = GroupsFinder.new(current_user, all_available: false).execute

    DashboardGroupMilestone.build_collection(groups)
  end

  # See [#39545](https://gitlab.com/gitlab-org/gitlab-ce/issues/39545) for info about the deprecation of dynamic milestones
  def dynamic_milestones
    DashboardMilestone.build_collection(@projects, params)
  end

  def milestones
    @milestones = group_milestones + dynamic_milestones
  end

  def milestone
    @milestone = DashboardMilestone.build(@projects, params[:title])
    render_404 unless @milestone
  end
end
