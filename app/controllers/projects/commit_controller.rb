# Controller for a specific Commit
#
# Not to be confused with CommitsController, plural.
class Projects::CommitController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :commit

  def show
    return git_not_found! unless @commit

    @line_notes = commit.notes.inline
    @diffs = @commit.diffs
    @note = @project.build_commit_note(commit)
    @notes_count = commit.notes.count
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

  def branches
    @branches = @project.repository.branch_names_contains(commit.id)
    @tags = @project.repository.tag_names_contains(commit.id)
    render layout: false
  end

  def commit
    @commit ||= @project.commit(params[:id])
  end
end
