# frozen_string_literal: true

class Dashboard::MilestonesController < Dashboard::ApplicationController
  include MilestoneActions

  before_action :projects
  before_action :groups, only: :index
  before_action :milestone, only: [:show, :merge_requests, :participants, :labels]

  def index
    respond_to do |format|
      format.html do
        @milestone_states = Milestone.states_count(@projects.select(:id), @groups.select(:id))
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

    DashboardGroupMilestone.build_collection(groups, params)
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

  def groups
    @groups ||= GroupsFinder.new(current_user, state_all: true).execute
  end
end
