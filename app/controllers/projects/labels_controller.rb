class Projects::LabelsController < Projects::ApplicationController
  before_action :module_enabled
  before_action :label, only: [:edit, :update, :destroy, :toggle_subscription]
  before_action :authorize_read_label!
  before_action :authorize_admin_labels!, only: [
    :new, :create, :edit, :update, :generate, :destroy, :remove_priority, :set_priorities
  ]

  respond_to :js, :html

  def index
    unprioritized_labels = @project.labels.unprioritized
    @global_labels = unprioritized_labels.with_type(:global_label).page(params[:page])
    @group_labels = unprioritized_labels.with_type(:group_label).page(params[:page])
    @labels = unprioritized_labels.with_type(:project_label).page(params[:page])
    @prioritized_labels = @project.labels.prioritized

    respond_to do |format|
      format.html
      format.json do
        render json: @project.labels
      end
    end
  end

  def new
    @label = @project.labels.new
  end

  def create
    service = Labels::CreateService.new(@project, current_user, label_params.merge(label_type: :project_label))

    @label = service.execute

    if @label.valid?
      redirect_to namespace_project_labels_path(@project.namespace, @project)
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    service = Labels::UpdateService.new(@project, current_user, label_params)

    if service.execute(@label)
      redirect_to namespace_project_labels_path(@project.namespace, @project)
    else
      render 'edit'
    end
  end

  def generate
    Labels::GenerateService.new(@project, current_user, label_type: :project_label).execute

    if params[:redirect] == 'issues'
      redirect_to namespace_project_issues_path(@project.namespace, @project)
    elsif params[:redirect] == 'merge_requests'
      redirect_to namespace_project_merge_requests_path(@project.namespace,
                                                        @project)
    else
      redirect_to namespace_project_labels_path(@project.namespace, @project)
    end
  end

  def destroy
    Labels::DestroyService.new(@project, current_user, label_type: :project_label).execute(@label)

    respond_to do |format|
      format.html do
        redirect_to(namespace_project_labels_path(@project.namespace, @project),
                    notice: 'Label was removed')
      end
      format.js
    end
  end

  def toggle_subscription
    return unless current_user

    Labels::ToggleSubscriptionService.new(@project, current_user, label_type: :project_label).execute(@label)

    head :ok
  end

  def remove_priority
    respond_to do |format|
      if label.update_attribute(:priority, nil)
        format.json { render json: label }
      else
        message = label.errors.full_messages.uniq.join('. ')
        format.json { render json: { message: message }, status: :unprocessable_entity }
      end
    end
  end

  def set_priorities
    Label.transaction do
      params[:label_ids].each_with_index do |label_id, index|
        label = @project.labels.find_by_id(label_id)
        label.update_attribute(:priority, index) if label
      end
    end

    respond_to do |format|
      format.json { render json: { message: 'success' } }
    end
  end

  protected

  def module_enabled
    unless @project.feature_available?(:issues, current_user) || @project.feature_available?(:merge_requests, current_user)
      return render_404
    end
  end

  def label_params
    params.require(:label).permit(:title, :description, :color)
  end

  def label
    @label ||= @project.labels.find(params[:id])
  end

  def authorize_admin_labels!
    return render_404 unless can?(current_user, :admin_label, @project)
  end
end
