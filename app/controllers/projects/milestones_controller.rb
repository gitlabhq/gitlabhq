# frozen_string_literal: true

class Projects::MilestonesController < Projects::ApplicationController
  include Gitlab::Utils::StrongMemoize
  include MilestoneActions

  REDIRECT_TARGETS = [:new_release].freeze

  before_action :check_issuables_available!
  before_action :milestone, only: [:edit, :update, :destroy, :show, :issues, :merge_requests, :participants, :labels, :promote]
  before_action :redirect_path, only: [:new, :create]

  # Allow read any milestone
  before_action :authorize_read_milestone!

  # Allow admin milestone
  before_action :authorize_admin_milestone!, except: [:index, :show, :issues, :merge_requests, :participants, :labels]

  # Allow to promote milestone
  before_action :authorize_promote_milestone!, only: :promote

  respond_to :html

  feature_category :team_planning
  urgency :low

  def index
    @sort = params[:sort] || 'due_date_asc'
    @milestones = milestones.sort_by_attribute(@sort)

    respond_to do |format|
      format.html do
        @milestone_states = Milestone.states_count(@project)
        # We need to show group milestones in the JSON response
        # so that people can filter by and assign group milestones,
        # but we don't need to show them on the project milestones page itself.
        @milestones = @milestones.for_projects
        @milestones = @milestones.page(params[:page])
      end
      format.json do
        render json: @milestones.to_json(only: [:id, :title, :due_date], methods: :name)
      end
    end
  end

  def new
    @noteable = @milestone = @project.milestones.new
    respond_with(@milestone)
  end

  def edit
    respond_with(@milestone)
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def create
    @milestone = Milestones::CreateService.new(project, current_user, milestone_params).execute

    if @milestone.valid?
      if @redirect_path == :new_release
        redirect_to new_project_release_path(@project)
      else
        redirect_to project_milestone_path(@project, @milestone)
      end
    else
      render "new"
    end
  end

  def update
    @milestone = Milestones::UpdateService.new(project, current_user, milestone_params).execute(milestone)

    respond_to do |format|
      format.html do
        if @milestone.valid?
          redirect_to project_milestone_path(@project, @milestone)
        else
          render :edit
        end
      end

      format.js

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

  def promote
    promoted_milestone = Milestones::PromoteService.new(project, current_user).execute(milestone)
    flash[:notice] = flash_notice_for(promoted_milestone, project_group)

    respond_to do |format|
      format.html do
        redirect_to project_milestones_path(project)
      end
      format.json do
        render json: { url: project_milestones_path(project) }
      end
    end
  rescue Milestones::PromoteService::PromoteMilestoneError => e
    redirect_to milestone, alert: e.message
  end

  def flash_notice_for(milestone, group)
    safe_link = view_context.link_to('<u>group milestone</u>'.html_safe, group_milestone_path(group, milestone.iid))
    view_context.safe_join([ERB::Util.html_escape(milestone.title), " promoted to ", safe_link, "."])
  end

  def destroy
    return access_denied! unless can?(current_user, :admin_milestone, @project)

    Milestones::DestroyService.new(project, current_user).execute(milestone)

    respond_to do |format|
      format.html { redirect_to namespace_project_milestones_path, status: :see_other }
      format.js { head :ok }
    end
  end

  protected

  def redirect_path
    path = params[:redirect_path]&.to_sym
    @redirect_path = path if REDIRECT_TARGETS.include?(path)
  end

  def project_group
    strong_memoize(:project_group) do
      project.group
    end
  end

  def milestones
    strong_memoize(:milestones) do
      MilestonesFinder.new(search_params).execute
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def milestone
    @noteable = @milestone ||= @project.milestones.find_by!(iid: params[:id])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def authorize_admin_milestone!
    render_404 unless can?(current_user, :admin_milestone, @project)
  end

  def authorize_promote_milestone!
    render_404 unless can?(current_user, :admin_milestone, project_group)
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

  def search_params
    if request.format.json? && project_group && can?(current_user, :read_group, project_group)
      groups = project_group.self_and_ancestors.select(:id)
    end

    params.permit(:state, :search_title).merge(project_ids: @project.id, group_ids: groups)
  end
end
