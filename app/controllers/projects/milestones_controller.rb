# frozen_string_literal: true

class Projects::MilestonesController < Projects::ApplicationController
  include Gitlab::Utils::StrongMemoize
  include MilestoneActions

  before_action :check_issuables_available!
  before_action :milestone, only: [:edit, :update, :destroy, :show, :issues, :merge_requests, :participants, :labels, :promote]

  # Allow read any milestone
  before_action :authorize_read_milestone!

  # Allow admin milestone
  before_action :authorize_admin_milestone!, except: [:index, :show, :issues, :merge_requests, :participants, :labels]

  # Allow to promote milestone
  before_action :authorize_promote_milestone!, only: :promote

  respond_to :html

  feature_category :issue_tracking

  def index
    @sort = params[:sort] || 'due_date_asc'
    @milestones = milestones.sort_by_attribute(@sort)

    respond_to do |format|
      format.html do
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
      redirect_to project_milestone_path(@project, @milestone)
    else
      render "new"
    end
  end

  def update
    @milestone = Milestones::UpdateService.new(project, current_user, milestone_params).execute(milestone)

    respond_to do |format|
      format.js
      format.html do
        if @milestone.valid?
          redirect_to project_milestone_path(@project, @milestone)
        else
          render :edit
        end
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
  rescue Milestones::PromoteService::PromoteMilestoneError => error
    redirect_to milestone, alert: error.message
  end

  def flash_notice_for(milestone, group)
    ''.html_safe + "#{milestone.title} promoted to " + view_context.link_to('<u>group milestone</u>'.html_safe, group_milestone_path(group, milestone.iid)) + '.'
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
    return render_404 unless can?(current_user, :admin_milestone, @project)
  end

  def authorize_promote_milestone!
    return render_404 unless can?(current_user, :admin_milestone, project_group)
  end

  def milestone_params
    params.require(:milestone).permit(:title, :description, :start_date, :due_date, :state_event)
  end

  def search_params
    if request.format.json? && project_group && can?(current_user, :read_group, project_group)
      groups = project_group.self_and_ancestors.select(:id)
    end

    params.permit(:state, :search_title).merge(project_ids: @project.id, group_ids: groups)
  end
end
