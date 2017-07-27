class Projects::RefsController < Projects::ApplicationController
  include ExtractsPath
  include TreeHelper
  include PathLocksHelper

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
            project_tree_path(@project, @id)
          when "blob"
            project_blob_path(@project, @id)
          when "graph"
            project_network_path(@project, @id, @options)
          when "graphs"
            project_graph_path(@project, @id)
          when "find_file"
            project_find_file_path(@project, @id)
          when "graphs_commits"
            commits_project_graph_path(@project, @id)
          when "badges"
            project_pipelines_settings_path(@project, ref: @id)
          else
            project_commits_path(@project, @id)
          end

        redirect_to new_path
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

    show_path_locks = @project.feature_available?(:file_locks) && @project.path_locks.any?

    @logs = contents[@offset, @limit].to_a.map do |content|
      file = @path ? File.join(@path, content.name) : content.name
      last_commit = @repo.last_commit_for_path(@commit.id, file)
      path_lock = show_path_locks && @project.find_path_lock(file)

      {
        file_name: content.name,
        commit: last_commit,
        lock_label: path_lock && text_label_for_lock(path_lock, file)
      }
    end

    offset = @offset + @limit

    if contents.size > offset
      @more_log_url = logs_file_project_ref_path(@project, @ref, @path || '', offset: offset)
    end

    respond_to do |format|
      format.html { render_404 }
      format.js
    end
  end

  private

  def validate_ref_id
    return not_found! if params[:id].present? && params[:id] !~ Gitlab::PathRegex.git_reference_regex
  end
end
