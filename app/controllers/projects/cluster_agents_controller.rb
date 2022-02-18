# frozen_string_literal: true

class Projects::ClusterAgentsController < Projects::ApplicationController
  before_action :authorize_can_read_cluster_agent!

  before_action do
    push_frontend_feature_flag(:cluster_vulnerabilities, project, default_enabled: :yaml)
  end

  feature_category :kubernetes_management

  def show
    @agent_name = params[:name]
  end

  private

  def authorize_can_read_cluster_agent!
    return if can?(current_user, :read_cluster, project)

    access_denied!
  end
end

Projects::ClusterAgentsController.prepend_mod_with('Projects::ClusterAgentsController')
