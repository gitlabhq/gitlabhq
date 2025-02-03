# frozen_string_literal: true

class Admin::ImpersonationTokensController < Admin::ApplicationController
  before_action :user
  before_action :verify_impersonation_enabled!

  feature_category :user_management

  def index
    set_index_vars
    @can_impersonate = helpers.can_impersonate_user(user, impersonation_in_progress?)
    @impersonation_error_text = helpers.impersonation_error_text(user, impersonation_in_progress?) if @can_impersonate
  end

  def create
    @impersonation_token = finder.build(impersonation_token_params)
    @impersonation_token.organization = Current.organization

    if @impersonation_token.save
      active_access_tokens = active_impersonation_tokens
      render json: { new_token: @impersonation_token.token,
                     active_access_tokens: active_access_tokens, total: active_access_tokens.length }, status: :ok
    else
      render json: { errors: @impersonation_token.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def revoke
    @impersonation_token = finder.find(params.permit(:id)[:id])

    if @impersonation_token.revoke!
      flash[:notice] = format(_("Revoked impersonation token %{token_name}!"), token_name: @impersonation_token.name)
    else
      flash[:alert] =
        format(_("Could not revoke impersonation token %{token_name}."), token_name: @impersonation_token.name)
    end

    redirect_to admin_user_impersonation_tokens_path
  end

  def rotate
    token = finder.find(params.permit(:id)[:id])
    result = PersonalAccessTokens::RotateService.new(current_user, token, nil, keep_token_lifetime: true).execute

    @impersonation_token = result.payload[:personal_access_token]
    if result.success?
      active_access_tokens = active_impersonation_tokens
      render json: { new_token: @impersonation_token.token,
                     active_access_tokens: active_access_tokens, total: active_access_tokens.length }, status: :ok
    else
      render json: { message: result.message }, status: :unprocessable_entity
    end
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def user
    @user ||= User.find_by!(username: params.permit(:user_id)[:user_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def verify_impersonation_enabled!
    access_denied! unless helpers.impersonation_tokens_enabled?
  end

  def finder(options = {})
    PersonalAccessTokensFinder.new({
      user: user,
      impersonation: true,
      organization: Current.organization
    }.merge(options))
  end

  def active_impersonation_tokens
    tokens = finder(state: 'active', sort: 'expires_at_asc_id_desc').execute
    ::ImpersonationAccessTokenSerializer.new.represent(tokens)
  end

  def impersonation_token_params
    params.require(:personal_access_token).permit(:name, :description, :expires_at, :impersonation, scopes: [])
  end

  def set_index_vars
    @scopes = Gitlab::Auth.available_scopes_for(current_user)

    @impersonation_token ||= finder.build
    @active_impersonation_tokens = active_impersonation_tokens
  end
end
