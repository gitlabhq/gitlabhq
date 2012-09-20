class CompareController < ApplicationController
  before_filter :project
  layout "project"

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    result = Commit.compare(project, params[:from], params[:to])

    @commits       = result[:commits]
    @commit        = result[:commit]
    @diffs         = result[:diffs]
    @refs_are_same = result[:same]
    @line_notes    = []

    @commits = CommitDecorator.decorate(@commits)
  end
end
