class Projects::DeployTokensController < Projects::ApplicationController
  before_action :authorize_admin_project!

  def create
    @token = DeployTokens::CreateService.new(@project, current_user, deploy_token_params).execute
    token_params = {}

    if @token.valid?
      flash[:notice] = 'Your new project deploy token has been created.'
    else
      token_params = @token.attributes.slice("name", "scopes", "expires_at")
      flash[:alert] = @token.errors.full_messages.join(', ').html_safe
    end

    redirect_to project_settings_repository_path(project, deploy_token: token_params)
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

  def authorize_admin_project!
    return render_404 unless can?(current_user, :admin_project, @project)
  end
end
