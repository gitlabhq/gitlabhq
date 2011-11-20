class RefsController < ApplicationController
  before_filter :project
  before_filter :ref
  layout "project"

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project

  def switch 
    new_path = if params[:destination] == "tree"
                 tree_project_ref_path(@project, params[:ref]) 
               else
                 project_commits_path(@project, :ref => params[:ref])
               end

    redirect_to new_path
  end

  #
  # Repository preview
  #
  def tree
    @repo = project.repo

    @commit = @repo.commits(@ref).first
    @tree = Tree.new(@commit.tree, project, @ref, params[:path])
    @tree = TreeDecorator.new(@tree)

    respond_to do |format|
      format.html
      format.js do
        # disable cache to allow back button works
        no_cache_headers
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
