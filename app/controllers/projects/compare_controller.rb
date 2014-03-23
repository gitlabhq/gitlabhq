class Projects::CompareController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def index
  end

  def show
    paths = params[:compare][:paths] rescue nil
    compare = Gitlab::Git::Compare.new(@repository.raw_repository, params[:from], params[:to], MergeRequestDiff::COMMITS_SAFE_SIZE)

    @commits       = compare.commits
    @commit        = compare.commit
    @diffs         = compare.diffs(paths)
    @refs_are_same = compare.same
    @line_notes    = []
    @timeout       = compare.timeout

    diff_line_count = Commit::diff_line_count(@diffs)
    @suppress_diff = Commit::diff_suppress?(@diffs, diff_line_count) && !params[:force_show_diff]
    @force_suppress_diff = Commit::diff_force_suppress?(@diffs, diff_line_count)

    gon.push({
      available_tags: @project.repository.ref_names,
      path_template: render_to_string(partial: 'path_fields', object: '', as: :path),
      available_paths: Gitlab::Diff::available_paths(compare.diffs)
    })
  end

  def create
    redirect_to project_compare_path(@project, params.slice(:from, :to, :compare))
  end
end
