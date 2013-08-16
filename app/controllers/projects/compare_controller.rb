class Projects::CompareController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def index
  end

  def show
    compare = Gitlab::Git::Compare.new(project.repository, params[:from], params[:to])

    @commits       = compare.commits
    @commit        = compare.commit
    @diffs         = compare.diffs
    @refs_are_same = compare.same
    @line_notes    = []
  end

  def create
    redirect_to project_compare_path(@project, params[:from], params[:to])
  end
end
