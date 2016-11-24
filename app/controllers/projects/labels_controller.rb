class Projects::LabelsController < Projects::ApplicationController
  include ToggleSubscriptionAction

  before_action :module_enabled
  before_action :label, only: [:edit, :update, :destroy]
  before_action :find_labels, only: [:index, :set_priorities, :remove_priority, :toggle_subscription]
  before_action :authorize_read_label!
  before_action :authorize_admin_labels!, only: [:new, :create, :edit, :update,
                                                 :generate, :destroy, :remove_priority,
                                                 :set_priorities]

  respond_to :js, :html

  def index
    @prioritized_labels = @available_labels.prioritized(@project)
    @labels = @available_labels.unprioritized(@project).page(params[:page])

    respond_to do |format|
      format.html
      format.json do
        render json: @available_labels.as_json(only: [:id, :title, :color])
      end
    end
  end

  def new
    @label = @project.labels.new
  end

  def create
    @label = @project.labels.create(label_params)

    if @label.valid?
      respond_to do |format|
        format.html { redirect_to namespace_project_labels_path(@project.namespace, @project) }
        format.json { render json: @label }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { message: @label.errors.messages }, status: 400 }
      end
    end
  end

  def edit
  end

  def update
    if @label.update_attributes(label_params)
      redirect_to namespace_project_labels_path(@project.namespace, @project)
    else
      render :edit
    end
  end

  def generate
    Gitlab::IssuesLabels.generate(@project)

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
    @label.destroy
    @labels = find_labels

    respond_to do |format|
      format.html do
        redirect_to(namespace_project_labels_path(@project.namespace, @project),
                    notice: 'Label was removed')
      end
      format.js
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

  def subscribable_resource
    @available_labels.find(params[:id])
  end

  def find_labels
    @available_labels ||= LabelsFinder.new(current_user, project_id: @project.id).execute
  end

  def authorize_admin_labels!
    return render_404 unless can?(current_user, :admin_label, @project)
  end
end
