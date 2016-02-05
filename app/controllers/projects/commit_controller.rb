# Controller for a specific Commit
#
# Not to be confused with CommitsController, plural.
class Projects::CommitController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!, except: [:cancel_builds, :retry_builds]
  before_action :authorize_update_build!, only: [:cancel_builds, :retry_builds]
  before_action :authorize_read_commit_status!, only: [:builds]
  before_action :commit
  before_action :define_show_vars, only: [:show, :builds]

  def show
    return git_not_found! unless @commit

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

  def badge
    image = Ci::ImageForBuildService.new.execute(@project, ref: params[:id])
    send_file(image.path, filename: image.name, disposition: 'inline', type: 'image/svg+xml')
  end

  private

  def commit
    @commit ||= @project.commit(params[:id])
  end

  def ci_commit
    @ci_commit ||= project.ci_commit(commit.sha)
  end

  def define_show_vars
    if params[:w].to_i == 1
      @diffs = commit.diffs({ ignore_whitespace_change: true })
    else
      @diffs = commit.diffs
    end

    @diff_refs = [commit.parent || commit, commit]
    @notes_count = commit.notes.count

    @statuses = ci_commit.statuses if ci_commit
  end
end
