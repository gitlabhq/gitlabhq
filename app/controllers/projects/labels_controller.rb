# frozen_string_literal: true

class Projects::LabelsController < Projects::ApplicationController
  include ToggleSubscriptionAction

  before_action :check_issuables_available!
  before_action :label, only: [:edit, :update, :destroy, :promote]
  before_action :find_labels, only: [:index, :set_priorities, :remove_priority, :toggle_subscription]
  before_action :authorize_read_label!
  before_action :authorize_admin_labels!, only: [:new, :create, :edit, :update,
    :generate, :destroy, :remove_priority,
    :set_priorities]
  before_action :authorize_admin_group_labels!, only: [:promote]

  respond_to :js, :html

  feature_category :team_planning
  urgency :low

  def index
    respond_to do |format|
      format.html do
        @prioritized_labels = @available_labels.prioritized(@project)
        @labels = @available_labels.unprioritized(@project).page(params[:page])
        # preload group, project, and subscription data
        Preloaders::LabelsPreloader.new(@prioritized_labels, current_user, @project).preload_all
        Preloaders::LabelsPreloader.new(@labels, current_user, @project).preload_all
      end
      format.json do
        render json: LabelSerializer.new.represent_appearance(@available_labels)
      end
    end
  end

  def new
    @label = @project.labels.new
  end

  def create
    @label = Labels::CreateService.new(label_params).execute(project: @project)

    if @label.valid?
      respond_to do |format|
        format.html { redirect_to project_labels_path(@project) }
        format.json { render json: @label }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { message: @label.errors.messages }, status: :bad_request }
      end
    end
  end

  def edit; end

  def update
    @label = Labels::UpdateService.new(label_params).execute(@label)

    if @label.valid?
      redirect_to project_labels_path(@project)
    else
      render :edit
    end
  end

  def generate
    Gitlab::IssuesLabels.generate(@project)

    case params[:redirect]
    when 'issues'
      redirect_to project_issues_path(@project)
    when 'merge_requests'
      redirect_to project_merge_requests_path(@project)
    else
      redirect_to project_labels_path(@project)
    end
  end

  def destroy
    if @label.destroy
      redirect_to project_labels_path(@project), status: :found,
        notice: format(_('%{label_name} was removed'), label_name: @label.name)
    else
      redirect_to project_labels_path(@project), status: :found,
        alert: @label.errors.full_messages.to_sentence
    end
  end

  def remove_priority
    respond_to do |format|
      label = @available_labels.find(params[:id])

      if label.unprioritize!(project)
        format.json { render json: label }
      else
        format.json { head :unprocessable_entity }
      end
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def set_priorities
    Label.transaction do
      available_labels_ids = @available_labels.where(id: params[:label_ids]).pluck(:id)
      label_ids = params[:label_ids].select { |id| available_labels_ids.include?(id.to_i) }

      label_ids.each_with_index do |label_id, index|
        label = @available_labels.find(label_id)
        label.prioritize!(project, index)
      end
    end

    respond_to do |format|
      format.json { render json: { message: 'success' } }
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def promote
    promote_service = Labels::PromoteService.new(@project, @current_user)

    begin
      return render_404 unless promote_service.execute(@label)

      flash[:notice] = flash_notice_for(@label, @project.group)
      respond_to do |format|
        format.html do
          redirect_to(project_labels_path(@project), status: :see_other)
        end
        format.json do
          render json: { url: project_labels_path(@project) }
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      Gitlab::AppLogger.error "Failed to promote label \"#{@label.title}\" to group label"
      Gitlab::AppLogger.error e

      respond_to do |format|
        format.html do
          redirect_to(
            project_labels_path(@project),
            notice: _('Failed to promote label due to internal error. Please contact administrators.'))
        end
        format.js
      end
    end
  end

  def flash_notice_for(label, group)
    safe_link = view_context.link_to('<u>group label</u>'.html_safe, group_labels_path(group))
    view_context.safe_join([ERB::Util.html_escape(label.title), " promoted to ", safe_link, "."])
  end

  protected

  def label_params
    allowed = [:title, :description, :color]
    allowed << :archived if Feature.enabled?(:labels_archive, :instance)
    allowed << :lock_on_merge if @project.supports_lock_on_merge?

    params.require(:label).permit(allowed)
  end

  def label
    @label ||= @project.labels.find(params[:id])
  end

  def subscribable_resource
    @available_labels.find(params[:id])
  end

  def find_labels
    @available_labels ||= LabelsFinder.new(
      current_user,
      project_id: @project.id,
      include_ancestor_groups: true,
      search: params[:search],
      subscribed: params[:subscribed],
      archived: params[:archived],
      sort: sort
    ).execute
  end

  def sort
    @sort ||= params[:sort] || 'name_asc'
  end

  def authorize_admin_labels!
    render_404 unless can?(current_user, :admin_label, @project)
  end

  def authorize_admin_group_labels!
    render_404 unless can?(current_user, :admin_label, @project.group)
  end
end
