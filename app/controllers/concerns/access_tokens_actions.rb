# frozen_string_literal: true

module AccessTokensActions
  extend ActiveSupport::Concern

  included do
    before_action -> { check_permission(:read_resource_access_tokens) }, only: [:index]
    before_action -> { check_permission(:destroy_resource_access_tokens) }, only: [:revoke]
    before_action -> { check_permission(:create_resource_access_tokens) }, only: [:create]
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def index
    @resource_access_token = PersonalAccessToken.new
    set_index_vars
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def create
    token_response = ResourceAccessTokens::CreateService.new(current_user, resource, create_params).execute

    if token_response.success?
      @resource_access_token = token_response.payload[:access_token]
      PersonalAccessToken.redis_store!(key_identity, @resource_access_token.token)

      redirect_to resource_access_tokens_path, notice: _("Your new access token has been created.")
    else
      redirect_to resource_access_tokens_path, alert: _("Failed to create new access token: %{token_response_message}") % { token_response_message: token_response.message }
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def revoke
    @resource_access_token = finder.find(params[:id])
    revoked_response = ResourceAccessTokens::RevokeService.new(current_user, resource, @resource_access_token).execute

    if revoked_response.success?
      flash[:notice] = _("Revoked access token %{access_token_name}!") % { access_token_name: @resource_access_token.name }
    else
      flash[:alert] = _("Could not revoke access token %{access_token_name}.") % { access_token_name: @resource_access_token.name }
    end

    redirect_to resource_access_tokens_path
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  private

  def check_permission(action)
    render_404 unless can?(current_user, action, resource)
  end

  def create_params
    params.require(:resource_access_token).permit(:name, :expires_at, :access_level, scopes: [])
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def set_index_vars
    # Loading resource members so that we can fetch access level of the bot
    # user in the resource without multiple queries.
    resource.members.load

    @scopes = Gitlab::Auth.resource_bot_scopes
    @active_resource_access_tokens = finder(state: 'active').execute.preload_users
    @inactive_resource_access_tokens = finder(state: 'inactive', sort: 'expires_at_asc').execute.preload_users
    @new_resource_access_token = PersonalAccessToken.redis_getdel(key_identity)
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def finder(options = {})
    PersonalAccessTokensFinder.new({ user: bot_users, impersonation: false }.merge(options))
  end

  def bot_users
    resource.bots
  end

  def key_identity
    "#{current_user.id}:#{resource.id}"
  end
end
