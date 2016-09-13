class JwtController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  before_action :authenticate_project_or_user

  SERVICES = {
    Auth::ContainerRegistryAuthenticationService::AUDIENCE => Auth::ContainerRegistryAuthenticationService,
  }

  def auth
    service = SERVICES[params[:service]]
    return head :not_found unless service

    result = service.new(@project, @user, auth_params).execute(capabilities: @capabilities)

    render json: result, status: result[:http_status]
  end

  private

  def authenticate_project_or_user
    authenticate_with_http_basic do |login, password|
      @auth_result = Gitlab::Auth.find_for_git_client(login, password, ip: request.ip)

      @user = auth_result.user
      @project = auth_result.project
      @type = auth_result.type
      @capabilities = auth_result.capabilities || []

      if @user || @project
        return # Allow access
      end

      render_403
    end
  end

  def auth_params
    params.permit(:service, :scope, :account, :client_id)
  end
end
