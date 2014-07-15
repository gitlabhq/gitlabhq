# Controller for a specific Commit
#
# Not to be confused with CommitsController, plural.
class Projects::CommitController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project
  before_filter :commit

  def show
    return git_not_found! unless @commit

    @line_notes = project.notes.for_commit_id(commit.id).inline

    @branches = begin
                  project.repository.branch_names_contains(commit.id)
                rescue Grit::Git::GitTimeout
                  []
                end

    begin
      @diffs = @commit.diffs
    rescue Grit::Git::GitTimeout
      @diffs = []
      @diff_timeout = true
    end

    @note = project.build_commit_note(commit)
    @notes_count = project.notes.for_commit_id(commit.id).count
    @notes = project.notes.for_commit_id(@commit.id).not_inline.fresh
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

  def commit
    @commit ||= project.repository.commit(params[:id])
  end
end
