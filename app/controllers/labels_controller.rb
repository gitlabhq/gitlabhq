class LabelsController < ProjectResourceController
  before_filter :module_enabled

  # Allow read any issue
  before_filter :authorize_read_issue!

  respond_to :js, :html

  def index
    @labels = @project.issues.tag_counts_on(:labels).order('count DESC')
  end

  protected

  def module_enabled
    return render_404 unless @project.issues_enabled
  end
end
