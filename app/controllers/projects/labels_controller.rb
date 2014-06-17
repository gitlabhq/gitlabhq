class Projects::LabelsController < Projects::ApplicationController
  before_filter :module_enabled

  before_filter :authorize_labels!

  respond_to :js, :html

  def index
    @labels = @project.issues_labels
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

  protected

  def module_enabled
    unless @project.issues_enabled || @project.merge_requests_enabled
      return render_404
    end
  end
end
