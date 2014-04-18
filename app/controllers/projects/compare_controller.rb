class Projects::CompareController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def index
  end

  def show
    compare = Gitlab::Git::Compare.new(@repository.raw_repository, params[:from], params[:to], MergeRequestDiff::COMMITS_SAFE_SIZE)

    @commits       = compare.commits
    @commit        = compare.commit
    @diffs         = compare.diffs
    @refs_are_same = compare.same
    @line_notes    = []
    @timeout       = compare.timeout

    diff_line_count = Commit::diff_line_count(@diffs)
    @suppress_diff = Commit::diff_suppress?(@diffs, diff_line_count) && !params[:force_show_diff]
    @force_suppress_diff = Commit::diff_force_suppress?(@diffs, diff_line_count)
  end

  def create
    redirect_to project_compare_path(@project, params[:from], params[:to])
  end
end
