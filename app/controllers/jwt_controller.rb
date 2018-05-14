class JwtController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  before_action :authenticate_project_or_user

  SERVICES = {
    Auth::ContainerRegistryAuthenticationService::AUDIENCE => Auth::ContainerRegistryAuthenticationService
  }.freeze

  def auth
    service = SERVICES[params[:service]]
    return head :not_found unless service

    result = service.new(@authentication_result.project, @authentication_result.actor, auth_params)
      .execute(authentication_abilities: @authentication_result.authentication_abilities)

    render json: result, status: result[:http_status]
  end

  private

  def authenticate_project_or_user
    @authentication_result = Gitlab::Auth::Result.new(nil, nil, :none, Gitlab::Auth.read_authentication_abilities)

    authenticate_with_http_basic do |login, password|
      @authentication_result = Gitlab::Auth.find_for_git_client(login, password, project: nil, ip: request.ip)

      if @authentication_result.failed?
        render_unauthorized
      end
    end
  rescue Gitlab::Auth::MissingPersonalAccessTokenError
    render_missing_personal_access_token
  end

  def render_missing_personal_access_token
    render json: {
      errors: [
        { code: 'UNAUTHORIZED',
          message: "HTTP Basic: Access denied\n" \
                   "You must use a personal access token with 'api' scope for Git over HTTP.\n" \
                   "You can generate one at #{profile_personal_access_tokens_url}" }
      ]
    }, status: 401
  end

  def render_unauthorized
    render json: {
      errors: [
        { code: 'UNAUTHORIZED',
          message: 'HTTP Basic: Access denied' }
      ]
    }, status: 401
  end

  def auth_params
    params.permit(:service, :scope, :account, :client_id)
  end
end
