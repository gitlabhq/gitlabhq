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

  def index
    @prioritized_labels = @available_labels.prioritized(@project)
    @labels = @available_labels.unprioritized(@project).page(params[:page])

    respond_to do |format|
      format.html
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
        format.json { render json: { message: @label.errors.messages }, status: 400 }
      end
    end
  end

  def edit
  end

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

    if params[:redirect] == 'issues'
      redirect_to project_issues_path(@project)
    elsif params[:redirect] == 'merge_requests'
      redirect_to project_merge_requests_path(@project)
    else
      redirect_to project_labels_path(@project)
    end
  end

  def destroy
    @label.destroy
    @labels = find_labels

    redirect_to project_labels_path(@project),
                status: 302,
                notice: 'Label was removed'
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

  def promote
    promote_service = Labels::PromoteService.new(@project, @current_user)

    begin
      return render_404 unless promote_service.execute(@label)

      flash[:notice] = "#{@label.title} promoted to <a href=#{group_labels_path(@project.group)}>group label.</a>".html_safe
      respond_to do |format|
        format.html do
          redirect_to(project_labels_path(@project), status: 303)
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
          redirect_to(project_labels_path(@project),
                      notice: 'Failed to promote label due to internal error. Please contact administrators.')
        end
        format.js
      end
    end
  end

  protected

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

  def authorize_admin_group_labels!
    return render_404 unless can?(current_user, :admin_label, @project.group)
  end
end
