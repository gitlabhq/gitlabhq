# frozen_string_literal: true

class Projects::DeployTokensController < Projects::ApplicationController
  before_action :authorize_destroy_deploy_token!

  feature_category :continuous_delivery
  urgency :low

  def revoke
    @token = @project.deploy_tokens.find(params[:id])
    @token.revoke!

    redirect_to project_settings_repository_path(project, anchor: 'js-deploy-tokens')
  end
end

Projects::DeployTokensController.prepend_mod
