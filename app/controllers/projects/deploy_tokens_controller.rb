class Projects::DeployTokensController < Projects::ApplicationController
  before_action :authorize_admin_project!

  def create
    @token = DeployTokens::CreateService.new(@project, current_user, deploy_token_params).execute

    if @token.valid?
      flash[:notice] = 'Your new project deploy token has been created.'
    end

    redirect_to project_settings_repository_path(project)
  end

  def revoke
    @token = @project.deploy_tokens.find(params[:id])
    @token.revoke!

    redirect_to project_settings_repository_path(project)
  end

  private

  def deploy_token_params
    params.require(:deploy_token).permit(:name, :expires_at, scopes: [])
  end
end
