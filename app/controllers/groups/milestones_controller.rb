# frozen_string_literal: true

class Groups::MilestonesController < Groups::ApplicationController
  include MilestoneActions

  before_action :milestone, only: [:edit, :show, :update, :issues, :merge_requests, :participants, :labels, :destroy]
  before_action :authorize_admin_milestones!, only: [:edit, :new, :create, :update, :destroy]

  feature_category :team_planning
  urgency :low

  def index
    respond_to do |format|
      format.html do
        @milestone_states = Milestone.states_count(group_projects_with_access.without_order, [group])
        @milestones = milestones.page(params[:page])
      end
      format.json do
        render json: milestones.to_json(only: [:id, :title, :due_date], methods: :name)
      end
    end
  end

  def new
    @noteable = @milestone = Milestone.new
  end

  def create
    @milestone = Milestones::CreateService.new(group, current_user, milestone_params).execute

    if @milestone.persisted?
      redirect_to milestone_path(@milestone)
    else
      render "new"
    end
  end

  def show; end

  def edit; end

  def update
    Milestones::UpdateService.new(@milestone.parent, current_user, milestone_params).execute(@milestone)

    respond_to do |format|
      format.html do
        if @milestone.valid?
          redirect_to milestone_path(@milestone)
        else
          render :edit
        end
      end

      format.json do
        if @milestone.valid?
          head :no_content
        else
          render json: { errors: @milestone.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::StaleObjectError
    respond_to do |format|
      format.html do
        @conflict = true
        render :edit
      end

      format.json do
        render json: {
          errors: [
            format(
              _("Someone edited this %{model_name} at the same time you did. Please refresh your browser and make sure your changes will not unintentionally remove theirs."),
              model_name: _('milestone')
            )
          ]
        }, status: :conflict
      end
    end
  end

  def destroy
    Milestones::DestroyService.new(group, current_user).execute(@milestone)

    respond_to do |format|
      format.html { redirect_to group_milestones_path(group), status: :see_other }
      format.js { head :ok }
    end
  end

  private

  def authorize_admin_milestones!
    render_404 unless can?(current_user, :admin_milestone, group)
  end

  def milestone_params
    params.require(:milestone)
    .permit(
      :description,
      :due_date,
      :lock_version,
      :start_date,
      :state_event,
      :title
    )
  end

  def milestones
    MilestonesFinder.new(search_params).execute
  end

  def milestone
    @noteable = @milestone ||= group.milestones.find_by_iid(params[:id])

    render_404 unless @milestone
  end

  def search_params
    groups = request.format.json? ? group_ids(include_ancestors: true) : group_ids

    @sort = params[:sort] || 'due_date_asc'
    params.permit(:state, :search_title).merge(sort: @sort, group_ids: groups, project_ids: group_projects_with_access)
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
end

Groups::MilestonesController.prepend_mod_with('Groups::MilestonesController')
