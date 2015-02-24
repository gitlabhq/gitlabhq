class Projects::LabelsController < Projects::ApplicationController
  before_filter :module_enabled
  before_filter :label, only: [:edit, :update, :destroy]
  before_filter :authorize_labels!
  before_filter :authorize_admin_labels!, except: [:index]

  respond_to :js, :html

  def index
    @labels = @project.labels.page(params[:page]).per(20)
  end

  def new
    @label = @project.labels.new
  end

  def create
    @label = @project.labels.create(label_params)

    if @label.valid?
      redirect_to namespace_project_labels_path(@project.namespace, @project)
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @label.update_attributes(label_params)
      redirect_to namespace_project_labels_path(@project.namespace, @project)
    else
      render 'edit'
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

    respond_to do |format|
      format.html do
        redirect_to(namespace_project_labels_path(@project.namespace, @project),
                    notice: 'Label was removed')
      end
      format.js
    end
  end

  protected

  def module_enabled
    unless @project.issues_enabled || @project.merge_requests_enabled
      return render_404
    end
  end

  def label_params
    params.require(:label).permit(:title, :color)
  end

  def label
    @label = @project.labels.find(params[:id])
  end

  def authorize_admin_labels!
    return render_404 unless can?(current_user, :admin_label, @project)
  end
end
