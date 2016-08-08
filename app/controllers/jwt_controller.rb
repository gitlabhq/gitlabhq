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

    result = service.new(@project, @user, auth_params).execute(access_type: @access_type)

    render json: result, status: result[:http_status]
  end

  private

  def authenticate_project_or_user
    authenticate_with_http_basic do |login, password|
      # if it's possible we first try to authenticate project with login and password
      @project, @user, @access_type = authenticate_build(login, password)
      return if @project

      @user, @access_type = authenticate_user(login, password)
      return if @user

      render_403
    end
  end

  def auth_params
    params.permit(:service, :scope, :account, :client_id)
  end

  def authenticate_build(login, password)
    return unless login == 'gitlab-ci-token'
    return unless password

    build = Ci::Build.running.find_by(token: password)
    return build.project, build.user, :restricted if build
  end

  def authenticate_user(login, password)
    user = Gitlab::Auth.find_with_user_password(login, password)
    Gitlab::Auth.rate_limit!(request.ip, success: user.present?, login: login)
    return user, :full
  end
end
