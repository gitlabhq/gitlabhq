class Projects::RefsController < Projects::ApplicationController
  include ExtractsPath

  before_filter :require_non_empty_project
  before_filter :assign_ref_vars
  before_filter :authorize_download_code!

  def switch
    respond_to do |format|
      format.html do
        new_path = if params[:destination] == "tree"
                     namespace_project_tree_path(@project.namespace, @project,
                                                 (@id))
                   elsif params[:destination] == "blob"
                     namespace_project_blob_path(@project.namespace, @project,
                                                 (@id))
                   elsif params[:destination] == "graph"
                     namespace_project_network_path(@project.namespace, @project, @id, @options)
                   else
                     namespace_project_commits_path(@project.namespace, @project, @id)
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
    contents.push(*tree.trees)
    contents.push(*tree.blobs)
    contents.push(*tree.submodules)

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
