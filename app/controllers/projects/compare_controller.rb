class Projects::CompareController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def index
  end

  def show
    base_ref = params[:from]
    head_ref = params[:to]

    compare_result = CompareService.new.execute(
      current_user,
      @project,
      head_ref,
      @project,
      base_ref
    )

    @commits = compare_result.commits
    @diffs = compare_result.diffs
    @commit = @commits.last
    @line_notes = []
  end

  def create
    redirect_to project_compare_path(@project, params[:from], params[:to])
  end
end
