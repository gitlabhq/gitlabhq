class Projects::RefsController < Projects::ApplicationController
  include ExtractsPath
  include TreeHelper

  before_action :require_non_empty_project
  before_action :validate_ref_id
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  def switch
    respond_to do |format|
      format.html do
        new_path =
          case params[:destination]
          when "tree"
            namespace_project_tree_path(@project.namespace, @project, @id)
          when "blob"
            namespace_project_blob_path(@project.namespace, @project, @id)
          when "graph"
            namespace_project_network_path(@project.namespace, @project, @id, @options)
          when "graphs"
            namespace_project_graph_path(@project.namespace, @project, @id)
          when "find_file"
            namespace_project_find_file_path(@project.namespace, @project, @id)
          when "graphs_commits"
            commits_namespace_project_graph_path(@project.namespace, @project, @id)
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

    offset = (@offset + @limit)
    if contents.size > offset
      @more_log_url = logs_file_namespace_project_ref_path(@project.namespace, @project, @ref, @path || '', offset: offset)
    end

    respond_to do |format|
      format.html { render_404 }
      format.js
    end
  end

  private

  def validate_ref_id
    return not_found! if params[:id].present? && params[:id] !~ Gitlab::Regex.git_reference_regex
  end
end
