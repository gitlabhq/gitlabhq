# Controller for a specific Commit
#
# Not to be confused with CommitsController, plural.
class CommitController < ApplicationController
  before_filter :project
  layout "project"

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    result = CommitLoad.new(project, current_user, params).execute

    @commit = result[:commit]

    if @commit
      @suppress_diff = result[:suppress_diff]
      @note          = result[:note]
      @line_notes    = result[:line_notes]
      @notes_count   = result[:notes_count]
      @comments_allowed = true
    else
      return git_not_found!
    end

    if result[:status] == :huge_commit
      render "huge_commit" and return
    end
  end
end
