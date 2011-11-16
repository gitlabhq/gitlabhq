class RefsController < ApplicationController
  before_filter :project
  before_filter :ref
  layout "project"

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project

  #
  # Repository preview
  #
  def tree
    @repo = project.repo

    @commit = @repo.commits(@ref).first
    @tree = @commit.tree
    @tree = @tree / params[:path] if params[:path]

    respond_to do |format|
      format.html # show.html.erb
      format.js do
        # diasbale cache to allow back button works
        response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
      end
    end
  rescue
    return render_404
  end

  def blob
    @repo = project.repo
    @commit = project.commit(@ref)
    @tree = project.tree(@commit, params[:path])

    if @tree.is_a?(Grit::Blob)
      send_data(@tree.data, :type => @tree.mime_type, :disposition => 'inline', :filename => @tree.name)
    else
      head(404)
    end
  rescue
    return render_404
  end

  protected

  def ref
    @ref = params[:id]
  end
end
