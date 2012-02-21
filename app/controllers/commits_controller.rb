require "base64"

class CommitsController < ApplicationController
  before_filter :project
  layout "project"

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project
  before_filter :load_refs, :only => :index # load @branch, @tag & @ref
  before_filter :render_full_content

  def index
    @repo = project.repo
    @limit, @offset = (params[:limit] || 40), (params[:offset] || 0)
    @commits = @project.commits(@ref, params[:path], @limit, @offset)

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.atom { render :layout => false }
    end
  end

  def show
    @commit = project.commit(params[:id])
    @notes = project.commit_notes(@commit).fresh.limit(20)
    @note = @project.build_commit_note(@commit)

    @comments_allowed = true
    @line_notes = project.commit_line_notes(@commit)

    respond_to do |format|
      format.html
      format.js { respond_with_notes }
    end
  end

  def compare
    first = project.commit(params[:to])
    last = project.commit(params[:from])

    @diffs = []
    @commits = []
    @line_notes = []

    if first && last
      commits = [first, last].sort_by(&:created_at)
      younger = commits.first
      older = commits.last


      @commits = project.repo.commits_between(younger.id, older.id).map {|c| Commit.new(c)}
      @diffs = project.repo.diff(younger.id, older.id) rescue []
      @commit = Commit.new(older)
    end
  end
end
