require "base64"

class Projects::CommitsController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    @repo = @project.repository
    @limit, @offset = (params[:limit] || 40), (params[:offset] || 0)

    @commits = @repo.commits(@ref, @path, @limit, @offset)

    respond_to do |format|
      format.html # index.html.erb
      format.json { pager_json("projects/commits/_commits", @commits.size) }
      format.atom { render layout: false }
    end
  end
end
