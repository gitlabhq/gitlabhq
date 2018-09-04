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
            project_settings_ci_cd_path(@project, ref: @id)
          else
            project_commits_path(@project, @id)
          end

        redirect_to new_path
      end
    end
  end

  def logs_tree
    summary = ::Gitlab::TreeSummary.new(
      @commit,
      @project,
      path: @path,
      offset: params[:offset],
      limit: 25
    )

    @logs, commits = summary.summarize
    @more_log_url = more_url(summary.next_offset) if summary.more?

    respond_to do |format|
      format.html { render_404 }
      format.json do
        response.headers["More-Logs-Url"] = @more_log_url if summary.more?
        render json: @logs
      end

      # The commit titles must be rendered and redacted before being shown.
      # Doing it here allows us to apply performance optimizations that avoid
      # N+1 problems
      format.js do
        prerender_commit_full_titles!(commits)
      end
    end
  end

  private

  def more_url(offset)
    logs_file_project_ref_path(@project, @ref, @path, offset: offset)
  end

  def prerender_commit_full_titles!(commits)
    renderer = Banzai::ObjectRenderer.new(user: current_user, default_project: @project)
    renderer.render(commits, :full_title)
  end

  def validate_ref_id
    return not_found! if params[:id].present? && params[:id] !~ Gitlab::PathRegex.git_reference_regex
  end
end
