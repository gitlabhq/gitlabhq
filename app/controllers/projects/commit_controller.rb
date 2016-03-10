# Controller for a specific Commit
#
# Not to be confused with CommitsController, plural.
class Projects::CommitController < Projects::ApplicationController
  include CreatesCommit
  include DiffHelper

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!, except: [:cancel_builds, :retry_builds]
  before_action :authorize_update_build!, only: [:cancel_builds, :retry_builds]
  before_action :authorize_read_commit_status!, only: [:builds]
  before_action :commit
  before_action :define_show_vars, only: [:show, :builds]
  before_action :authorize_edit_tree!, only: [:revert]

  def show
    apply_diff_view_cookie!

    @line_notes = commit.notes.inline
    @note = @project.build_commit_note(commit)
    @notes = commit.notes.not_inline.fresh
    @noteable = @commit
    @comments_allowed = @reply_allowed = true
    @comments_target  = {
      noteable_type: 'Commit',
      commit_id: @commit.id
    }

    respond_to do |format|
      format.html
      format.diff  { render text: @commit.to_diff }
      format.patch { render text: @commit.to_patch }
    end
  end

  def builds
  end

  def cancel_builds
    ci_commit.builds.running_or_pending.each(&:cancel)

    redirect_back_or_default default: builds_namespace_project_commit_path(project.namespace, project, commit.sha)
  end

  def retry_builds
    ci_commit.builds.latest.failed.each do |build|
      if build.retryable?
        Ci::Build.retry(build)
      end
    end

    redirect_back_or_default default: builds_namespace_project_commit_path(project.namespace, project, commit.sha)
  end

  def branches
    @branches = @project.repository.branch_names_contains(commit.id)
    @tags = @project.repository.tag_names_contains(commit.id)
    render layout: false
  end

  def revert
    assign_revert_commit_vars

    return render_404 if @target_branch.blank?

    create_commit(Commits::RevertService, success_notice: "The #{revert_type_title} has been successfully reverted.",
                                          success_path: successful_revert_path, failure_path: failed_revert_path)
  end

  private

  def revert_type_title
    @commit.merged_merge_request ? 'merge request' : 'commit'
  end

  def successful_revert_path
    return referenced_merge_request_url if @commit.merged_merge_request

    namespace_project_commits_url(@project.namespace, @project, @target_branch)
  end

  def failed_revert_path
    return referenced_merge_request_url if @commit.merged_merge_request

    namespace_project_commit_url(@project.namespace, @project, params[:id])
  end

  def referenced_merge_request_url
    namespace_project_merge_request_url(@project.namespace, @project, @commit.merged_merge_request)
  end

  def commit
    @commit ||= @project.commit(params[:id])
  end

  def ci_commit
    @ci_commit ||= project.ci_commit(commit.sha)
  end

  def define_show_vars
    return git_not_found! unless commit

    opts = diff_options
    opts[:ignore_whitespace_change] = true if params[:format] == 'diff'

    @diffs = commit.diffs(opts)
    @diff_refs = [commit.parent || commit, commit]
    @notes_count = commit.notes.count

    @statuses = ci_commit.statuses if ci_commit
  end

  def assign_revert_commit_vars
    @commit = project.commit(params[:id])
    @target_branch = params[:target_branch]
    @mr_source_branch = @commit.revert_branch_name
    @mr_target_branch = @target_branch
    @commit_params = {
      commit: @commit,
      revert_type_title: revert_type_title,
      create_merge_request: params[:create_merge_request].present? || different_project?
    }
  end
end
