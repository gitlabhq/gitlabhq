class RefsController < ProjectResourceController
  include Gitlab::Encode

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  before_filter :ref
  before_filter :define_tree_vars, only: [:blob, :logs_tree]

  def switch 
    respond_to do |format| 
      format.html do 
        new_path = if params[:destination] == "tree"
                     project_tree_path(@project, @ref)
                   else
                     project_commits_path(@project, @ref)
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

  protected

  def define_tree_vars
    params[:path] = nil if params[:path].blank?

    @repo = project.repo
    @commit = project.commit(@ref)
    @commit = CommitDecorator.decorate(@commit)
    @tree = Tree.new(@commit.tree, project, @ref, params[:path])
    @tree = TreeDecorator.new(@tree)
    @hex_path = Digest::SHA1.hexdigest(params[:path] || "")

    if params[:path]
      @history_path = project_tree_path(@project, File.join(@ref, params[:path]))
      @logs_path = logs_file_project_ref_path(@project, @ref, params[:path])
    else
      @history_path = project_tree_path(@project, @ref)
      @logs_path = logs_tree_project_ref_path(@project, @ref)
    end
  rescue
    return render_404
  end

  def ref
    @ref = params[:id] || params[:ref]
  end
end
