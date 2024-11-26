# frozen_string_literal: true

class JwtController < ApplicationController
  skip_around_action :set_session_storage
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  # Add this before other actions, since we want to have the user or project
  prepend_before_action :auth_user, :authenticate_project_or_user
  around_action :bypass_admin_mode!, if: :auth_user

  feature_category :container_registry
  # https://gitlab.com/gitlab-org/gitlab/-/issues/357037
  urgency :low

  SERVICES = {
    ::Auth::ContainerRegistryAuthenticationService::AUDIENCE => ::Auth::ContainerRegistryAuthenticationService,
    ::Auth::DependencyProxyAuthenticationService::AUDIENCE => ::Auth::DependencyProxyAuthenticationService
  }.freeze

  # Currently POST requests for this route return a 404 by default and are allowed through in our readonly middleware -
  # ee/lib/ee/gitlab/middleware/read_only/controller.rb
  # If the action here changes to allow POST requests then a check for maintenance mode should be added
  def auth
    service = SERVICES[params[:service]]
    return head :not_found unless service

    result = service.new(@authentication_result.project, auth_user, auth_params)
      .execute(authentication_abilities: @authentication_result.authentication_abilities)

    render json: result, status: result[:http_status]
  end

  private

  def authenticate_project_or_user
    @authentication_result = Gitlab::Auth::Result.new(
      nil,
      nil,
      :none,
      Gitlab::Auth.read_only_authentication_abilities
    )

    authenticate_with_http_basic do |login, password|
      @authentication_result = Gitlab::Auth.find_for_git_client(login, password, project: nil, request: request)

      @raw_token = password if @authentication_result.type == :personal_access_token

      if @authentication_result.failed?
        log_authentication_failed(login, @authentication_result)
        render_access_denied
      end
    end
  rescue Gitlab::Auth::MissingPersonalAccessTokenError
    render_access_denied
  end

  def log_authentication_failed(login, result)
    log_info = {
      message: 'JWT authentication failed',
      http_user: login,
      remote_ip: request.ip,
      auth_service: params[:service],
      'auth_result.type': result.type,
      'auth_result.actor_type': result.actor&.class
    }.merge(::Gitlab::ApplicationContext.current)

    Gitlab::AuthLogger.warn(log_info)
  end

  def render_access_denied
    help_page = help_page_url(
      'user/profile/account/two_factor_authentication_troubleshooting.md',
      anchor: 'error-http-basic-access-denied-if-a-password-was-provided-for-git-authentication-'
    )

    render(
      json: {
        errors: [{
          code: 'UNAUTHORIZED',
          message: format(_("HTTP Basic: Access denied. If a password was provided for Git authentication, the " \
            "password was incorrect or you're required to use a token instead of a password. If a " \
            "token was provided, it was either incorrect, expired, or improperly scoped. See " \
            "%{help_page_url}"), help_page_url: help_page)
        }]
      },
      status: :unauthorized
    )
  end

  def auth_params
    params.permit(:service, :account, :client_id)
          .merge(additional_params)
  end

  def additional_params
    {
      scopes: scopes_param,
      raw_token: @raw_token,
      deploy_token: @authentication_result.deploy_token,
      auth_type: @authentication_result.type
    }.compact
  end

  # We have to parse scope here, because Docker Client does not send an array of scopes,
  # but rather a flat list and we loose second scope when being processed by Rails:
  # scope=scopeA&scope=scopeB.
  #
  # Additionally, according to RFC6749 (https://datatracker.ietf.org/doc/html/rfc6749#section-3.3), some clients may use
  # a scope parameter expressed as a list of space-delimited elements. Therefore, we must account for this and split the
  # scope parameter value(s) appropriately.
  #
  # This method makes to always return an array of scopes
  def scopes_param
    return unless params[:scope].present?

    scopes = Array(Rack::Utils.parse_query(request.query_string)['scope'])
    scopes.flat_map(&:split)
  end

  def auth_user
    strong_memoize(:auth_user) do
      @authentication_result.auth_user
    end
  end

  def bypass_admin_mode!(&)
    return yield unless Gitlab::CurrentSettings.admin_mode

    Gitlab::Auth::CurrentUserMode.bypass_session!(auth_user.id, &)
  end
end
