# frozen_string_literal: true

class Projects::GoogleCloudController < Projects::ApplicationController
  before_action :authorize_can_manage_google_cloud_deployments!

  feature_category :release_orchestration

  def index
  end

  private

  def authorize_can_manage_google_cloud_deployments!
    access_denied! unless can?(current_user, :manage_project_google_cloud, project)
  end
end
