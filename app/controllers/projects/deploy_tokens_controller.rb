class Projects::DeployTokensController < Projects::ApplicationController
  before_action :authorize_admin_project!

  def revoke
    @token = @project.deploy_tokens.find(params[:id])
    @token.revoke!

    redirect_to project_settings_repository_path(project)
  end

  private

  def deploy_token_params
    params.require(:deploy_token).permit(:name, :expires_at, :read_repository, :read_registry)
  end
end
