# frozen_string_literal: true

class Groups::DeployTokensController < Groups::ApplicationController
  before_action :authorize_destroy_deploy_token!

  feature_category :continuous_delivery
  urgency :low

  def revoke
    Groups::DeployTokens::RevokeService.new(@group, current_user, params).execute

    redirect_to group_settings_repository_path(@group, anchor: 'js-deploy-tokens')
  end
end
