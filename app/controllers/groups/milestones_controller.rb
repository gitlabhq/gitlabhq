# frozen_string_literal: true

class Groups::MilestonesController < Groups::ApplicationController
  include MilestoneActions

  before_action :milestone, only: [:edit, :show, :update, :merge_requests, :participants, :labels, :destroy]
  before_action :authorize_admin_milestones!, only: [:edit, :new, :create, :update, :destroy]
  before_action do
    push_frontend_feature_flag(:burnup_charts)
  end

  def index
    respond_to do |format|
      format.html do
        @milestone_states = Milestone.states_count(group_projects_with_access, [group])
        @milestones = Kaminari.paginate_array(milestones).page(params[:page])
      end
      format.json do
        render json: milestones.map { |m| m.for_display.slice(:id, :title, :name) }
      end
    end
  end

  def new
    @milestone = Milestone.new
  end

  def create
    @milestone = Milestones::CreateService.new(group, current_user, milestone_params).execute

    if @milestone.persisted?
      redirect_to milestone_path
    else
      render "new"
    end
  end

  def show
  end

  def edit
    render_404 if @milestone.legacy_group_milestone?
  end

  def update
    # Keep this compatible with legacy group milestones where we have to update
    # all projects milestones states at once.
    milestones, update_params = get_milestones_for_update
    milestones.each do |milestone|
      Milestones::UpdateService.new(milestone.resource_parent, current_user, update_params).execute(milestone)
    end

    redirect_to milestone_path
  end

  def destroy
    return render_404 if @milestone.legacy_group_milestone?

    Milestones::DestroyService.new(group, current_user).execute(@milestone)

    respond_to do |format|
      format.html { redirect_to group_milestones_path(group), status: :see_other }
      format.js { head :ok }
    end
  end

  private

  def get_milestones_for_update
    if @milestone.legacy_group_milestone?
      [@milestone.milestones, legacy_milestone_params]
    else
      [[@milestone], milestone_params]
    end
  end

  def authorize_admin_milestones!
    return render_404 unless can?(current_user, :admin_milestone, group)
  end

  def milestone_params
    params.require(:milestone).permit(:title, :description, :start_date, :due_date, :state_event)
  end

  def legacy_milestone_params
    params.require(:milestone).permit(:state_event)
  end

  def milestone_path
    if @milestone.legacy_group_milestone?
      group_milestone_path(group, @milestone.safe_title, title: @milestone.title)
    else
      group_milestone_path(group, @milestone.iid)
    end
  end

  def milestones
    milestones = MilestonesFinder.new(search_params).execute

    @sort = params[:sort] || 'due_date_asc'
    MilestoneArray.sort(milestones + legacy_milestones, @sort)
  end

  def legacy_milestones
    GroupMilestone.build_collection(group, group_projects_with_access, params)
  end

  def group_projects_with_access
    group_projects_with_subgroups.with_issues_or_mrs_available_for_user(current_user)
  end

  def group_ids(include_ancestors: false)
    if include_ancestors
      group.self_and_hierarchy.public_or_visible_to_user(current_user).select(:id)
    else
      group.self_and_descendants.public_or_visible_to_user(current_user).select(:id)
    end
  end

  def milestone
    @milestone =
      if params[:title]
        GroupMilestone.build(group, group_projects_with_access, params[:title])
      else
        group.milestones.find_by_iid(params[:id])
      end

    render_404 unless @milestone
  end

  def search_params
    groups = request.format.json? ? group_ids(include_ancestors: true) : group_ids

    params.permit(:state, :search_title).merge(group_ids: groups)
  end
end

Groups::MilestonesController.prepend_if_ee('EE::Groups::MilestonesController')
