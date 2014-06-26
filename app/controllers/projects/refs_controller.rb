class Projects::RefsController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def switch
    respond_to do |format|
      format.html do
        new_path = if params[:destination] == "tree"
                     project_tree_path(@project, (@id))
                   elsif params[:destination] == "blob"
                     project_blob_path(@project, (@id))
                   elsif params[:destination] == "graph"
                     project_network_path(@project, @id, @options)
                   else
                     project_commits_path(@project, @id)
                   end

        redirect_to new_path
      end
      format.js do
        @ref = params[:ref]
        define_tree_vars
        tree
        render "tree"
      end
    end
  end

  def logs_tree
    @offset = if params[:offset].present?
             params[:offset].to_i
           else
             0
           end

    @limit = 25

    @path = params[:path]

    contents = []
    contents += tree.trees
    contents += tree.blobs
    contents += tree.submodules

    @logs = contents[@offset, @limit].to_a.map do |content|
      file = @path ? File.join(@path, content.name) : content.name
      last_commit = @repo.last_commit_for_path(@commit.id, file)
      {
        file_name: content.name,
        commit: last_commit
      }
    end
  end
end
