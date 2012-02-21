class RefsController < ApplicationController
  before_filter :project

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  before_filter :ref
  before_filter :define_tree_vars, :only => [:tree, :blob]
  before_filter :render_full_content

  layout "project"

  def switch 
    respond_to do |format| 
      format.html do 
        new_path = if params[:destination] == "tree"
                     tree_project_ref_path(@project, params[:ref]) 
                   else
                     project_commits_path(@project, :ref => params[:ref])
                   end

        redirect_to new_path 
      end
      format.js do 
        @ref = params[:ref]
        define_tree_vars
        render "tree"
      end
    end
  end

  #
  # Repository preview
  #
  def tree
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
    if @tree.is_blob?
      send_data(
        @tree.data,
        :type => @tree.text? ? "text/plain" : @tree.mime_type,
        :disposition => 'inline',
        :filename => @tree.name
      )
    else
      head(404)
    end
  rescue
    return render_404
  end

  protected

  def define_tree_vars
    params[:path] = nil if params[:path].blank?

    @repo = project.repo
    @commit = project.commit(@ref)
    @tree = Tree.new(@commit.tree, project, @ref, params[:path])
    @tree = TreeDecorator.new(@tree)
  rescue
    return render_404
  end
    
  def ref
    @ref = params[:id]
  end
end
