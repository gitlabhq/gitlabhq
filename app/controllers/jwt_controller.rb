# frozen_string_literal: true

class JwtController < ApplicationController
  skip_around_action :set_session_storage
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  # Add this before other actions, since we want to have the user or project
  prepend_before_action :auth_user, :authenticate_project_or_user

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
    @authentication_result = Gitlab::Auth::Result.new(nil, nil, :none, Gitlab::Auth.read_only_authentication_abilities)

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
          message: _('HTTP Basic: Access denied\n' \
                   'You must use a personal access token with \'api\' scope for Git over HTTP.\n' \
                   'You can generate one at %{profile_personal_access_tokens_url}') % { profile_personal_access_tokens_url: profile_personal_access_tokens_url } }
      ]
    }, status: :unauthorized
  end

  def render_unauthorized
    render json: {
      errors: [
        { code: 'UNAUTHORIZED',
          message: 'HTTP Basic: Access denied' }
      ]
    }, status: :unauthorized
  end

  def auth_params
    params.permit(:service, :account, :client_id)
          .merge(additional_params)
  end

  def additional_params
    { scopes: scopes_param }.compact
  end

  # We have to parse scope here, because Docker Client does not send an array of scopes,
  # but rather a flat list and we loose second scope when being processed by Rails:
  # scope=scopeA&scope=scopeB
  #
  # This method makes to always return an array of scopes
  def scopes_param
    return unless params[:scope].present?

    Array(Rack::Utils.parse_query(request.query_string)['scope'])
  end

  def auth_user
    strong_memoize(:auth_user) do
      actor = @authentication_result&.actor
      actor.is_a?(User) ? actor : nil
    end
  end
end
