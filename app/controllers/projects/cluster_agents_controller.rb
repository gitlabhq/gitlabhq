# frozen_string_literal: true

class Projects::ClusterAgentsController < Projects::ApplicationController
  before_action :authorize_can_read_cluster_agent!

  feature_category :kubernetes_management

  def show
    @agent_name = params[:name]
  end

  private

  def authorize_can_read_cluster_agent!
    return if can?(current_user, :admin_cluster, project)

    access_denied!
  end
end
