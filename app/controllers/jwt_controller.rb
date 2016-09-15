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

    @@authentication_result ||= Gitlab::Auth.Result.new

    result = service.new(@authentication_result.project, @authentication_result.user, auth_params).
      execute(capabilities: @authentication_result.capabilities || [])

    render json: result, status: result[:http_status]
  end

  private

  def authenticate_project_or_user
    authenticate_with_http_basic do |login, password|
      @authentication_result = Gitlab::Auth.find_for_git_client(login, password, ip: request.ip)

      render_403 unless @authentication_result.succeeded?
    end
  end

  def auth_params
    params.permit(:service, :scope, :account, :client_id)
  end
end
