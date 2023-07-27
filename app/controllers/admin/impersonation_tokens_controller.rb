# frozen_string_literal: true

class Admin::ImpersonationTokensController < Admin::ApplicationController
  before_action :user
  before_action :verify_impersonation_enabled!

  feature_category :user_management

  def index
    set_index_vars
    @can_impersonate = helpers.can_impersonate_user(user, impersonation_in_progress?)
    @impersonation_error_text = @can_impersonate ? nil : helpers.impersonation_error_text(user, impersonation_in_progress?)
  end

  def create
    @impersonation_token = finder.build(impersonation_token_params)

    if @impersonation_token.save
      render json: { new_token: @impersonation_token.token,
                     active_access_tokens: active_impersonation_tokens }, status: :ok
    else
      render json: { errors: @impersonation_token.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def revoke
    @impersonation_token = finder.find(params[:id])

    if @impersonation_token.revoke!
      flash[:notice] = format(_("Revoked impersonation token %{token_name}!"), token_name: @impersonation_token.name)
    else
      flash[:alert] = format(_("Could not revoke impersonation token %{token_name}."), token_name: @impersonation_token.name)
    end

    redirect_to admin_user_impersonation_tokens_path
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def user
    @user ||= User.find_by!(username: params[:user_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def verify_impersonation_enabled!
    access_denied! unless helpers.impersonation_enabled?
  end

  def finder(options = {})
    PersonalAccessTokensFinder.new({ user: user, impersonation: true }.merge(options))
  end

  def active_impersonation_tokens
    tokens = finder(state: 'active', sort: 'expires_at_asc_id_desc').execute
    ::ImpersonationAccessTokenSerializer.new.represent(tokens)
  end

  def impersonation_token_params
    params.require(:personal_access_token).permit(:name, :expires_at, :impersonation, scopes: [])
  end

  def set_index_vars
    @scopes = Gitlab::Auth.available_scopes_for(current_user)

    @impersonation_token ||= finder.build
    @active_impersonation_tokens = active_impersonation_tokens
  end
end
