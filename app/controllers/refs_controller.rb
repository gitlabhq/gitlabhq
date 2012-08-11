class RefsController < ApplicationController
  include Gitlab::Encode
  before_filter :project

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  before_filter :ref
  before_filter :define_tree_vars, only: [:tree, :blob, :blame, :logs_tree]
  before_filter :render_full_content

  layout "project"

  def switch 
    respond_to do |format| 
      format.html do 
        new_path = if params[:destination] == "tree"
                     tree_project_ref_path(@project, params[:ref]) 
                   else
                     project_commits_path(@project, ref: params[:ref])
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
  end

  def logs_tree
    contents = @tree.contents
    @logs = contents.map do |content|
      file = params[:path] ? File.join(params[:path], content.name) : content.name
      last_commit = @project.commits(@commit.id, file, 1).last
      last_commit = CommitDecorator.decorate(last_commit)
      {
        file_name: content.name, 
        commit: last_commit
      }
    end
  end

  def blob
    if @tree.is_blob?
      if @tree.text?
        encoding = detect_encoding(@tree.data)
        mime_type = encoding ? "text/plain; charset=#{encoding}" : "text/plain"
      else
        mime_type = @tree.mime_type
      end

      send_data(
        @tree.data,
        type: mime_type,
        disposition: 'inline',
        filename: @tree.name
      )
    else
      head(404)
    end
  end

  def blame
    @blame = Grit::Blob.blame(@repo, @commit.id, params[:path])
  end

  protected

  def define_tree_vars
    params[:path] = nil if params[:path].blank?

    @repo = project.repo
    @commit = project.commit(@ref)
    @commit = CommitDecorator.decorate(@commit)
    @tree = Tree.new(@commit.tree, project, @ref, params[:path])
    @tree = TreeDecorator.new(@tree)
    @hex_path = Digest::SHA1.hexdigest(params[:path] || "/")

    if params[:path]
      @history_path = tree_file_project_ref_path(@project, @ref, params[:path])
      @logs_path = logs_file_project_ref_path(@project, @ref, params[:path]) 
    else
      @history_path = tree_project_ref_path(@project, @ref)
      @logs_path = logs_tree_project_ref_path(@project, @ref) 
    end
  rescue
    return render_404
  end
    
  def ref
    @ref = params[:id]
  end
end
