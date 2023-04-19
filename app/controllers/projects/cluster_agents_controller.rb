# frozen_string_literal: true

class Projects::ClusterAgentsController < Projects::ApplicationController
  include KasCookie

  before_action :authorize_read_cluster_agent!
  before_action :set_kas_cookie, only: [:show], if: -> { current_user }

  feature_category :deployment_management
  urgency :low

  def show
    @agent_name = params[:name]
  end
end

Projects::ClusterAgentsController.prepend_mod_with('Projects::ClusterAgentsController')
