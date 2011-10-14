require "base64"

class CommitsController < ApplicationController
  before_filter :project

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!

  def index
    load_refs # load @branch, @tag & @ref

    @repo = project.repo

    if params[:path]
      @commits = @repo.log(@ref, params[:path], :max_count => params[:limit] || 100, :skip => params[:offset] || 0)
    else
      @commits = @repo.commits(@ref, params[:limit] || 100, params[:offset] || 0)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
    end
  end

  def show
    @commit = project.repo.commits(params[:id]).first
    @notes = project.notes.where(:noteable_id => @commit.id, :noteable_type => "Commit")
    @note = @project.notes.new(:noteable_id => @commit.id, :noteable_type => "Commit")

    respond_to do |format|
      format.html # show.html.erb
      format.js
    end
  end
end
