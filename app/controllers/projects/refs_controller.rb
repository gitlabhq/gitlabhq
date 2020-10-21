# frozen_string_literal: true

class Projects::RefsController < Projects::ApplicationController
  include ExtractsPath
  include TreeHelper

  around_action :allow_gitaly_ref_name_caching, only: [:logs_tree]

  before_action :require_non_empty_project
  before_action :validate_ref_id
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  feature_category :source_code_management

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
    tree_summary = ::Gitlab::TreeSummary.new(
      @commit, @project, current_user,
      path: @path, offset: params[:offset], limit: 25)

    respond_to do |format|
      format.html { render_404 }
      format.json do
        logs, next_offset = tree_summary.fetch_logs

        response.headers["More-Logs-Offset"] = next_offset.to_s if next_offset

        render json: logs
      end
    end
  end

  private

  def validate_ref_id
    return not_found! if params[:id].present? && params[:id] !~ Gitlab::PathRegex.git_reference_regex
  end
end
