require "base64"

class CommitsController < ApplicationController
  before_filter :project
  layout "project"

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project
  before_filter :load_refs, only: :index # load @branch, @tag & @ref
  before_filter :render_full_content

  def index
    @repo = project.repo
    @limit, @offset = (params[:limit] || 40), (params[:offset] || 0)

    @commits = @project.commits(@ref, params[:path], @limit, @offset)
    @commits = CommitDecorator.decorate(@commits)

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.atom { render layout: false }
    end
  end

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

  def compare
    result = Commit.compare(project, params[:from], params[:to])

    @commits = result[:commits]
    @commit  = result[:commit]
    @diffs   = result[:diffs]
    @line_notes = []

    @commits = CommitDecorator.decorate(@commits)
  end

  def patch
    @commit = project.commit(params[:id])
    
    send_data(
      @commit.to_patch,
      type: "text/plain",
      disposition: 'attachment',
      filename: (@commit.id.to_s + ".patch")
    )
  end
end
