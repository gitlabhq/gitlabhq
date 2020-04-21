# frozen_string_literal: true

class Groups::DeployTokensController < Groups::ApplicationController
  before_action :authorize_admin_group!

  def revoke
    @token = @group.deploy_tokens.find(params[:id])
    @token.revoke!

    redirect_to group_settings_repository_path(@group, anchor: 'js-deploy-tokens')
  end
end
