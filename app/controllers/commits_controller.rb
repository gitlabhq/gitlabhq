require "base64"

class CommitsController < ApplicationController
  before_filter :project
  layout "project"

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project
  before_filter :load_refs, :only => :index # load @branch, @tag & @ref

  def index
    @repo = project.repo
    limit, offset = (params[:limit] || 20), (params[:offset] || 0)

    @commits = if params[:path]
                 @repo.log(@ref, params[:path], :max_count => limit, :skip => offset)
               else
                 @repo.commits(@ref, limit, offset)
               end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.atom { render :layout => false }
    end
  end

  def show
    @commit = project.repo.commits(params[:id]).first
    @notes = project.commit_notes(@commit).fresh.limit(20)
    @note = @project.build_commit_note(@commit)

    respond_to do |format|
      format.html
      format.js { respond_with_notes }
    end
  end
end
