# frozen_string_literal: true

class Admin::ImpersonationTokensController < Admin::ApplicationController
  before_action :user

  feature_category :authentication_and_authorization

  def index
    set_index_vars
  end

  def create
    @impersonation_token = finder.build(impersonation_token_params)

    if @impersonation_token.save
      PersonalAccessToken.redis_store!(current_user.id, @impersonation_token.token)
      redirect_to admin_user_impersonation_tokens_path, notice: _("A new impersonation token has been created.")
    else
      set_index_vars
      render :index
    end
  end

  def revoke
    @impersonation_token = finder.find(params[:id])

    if @impersonation_token.revoke!
      flash[:notice] = _("Revoked impersonation token %{token_name}!") % { token_name: @impersonation_token.name }
    else
      flash[:alert] = _("Could not revoke impersonation token %{token_name}.") % { token_name: @impersonation_token.name }
    end

    redirect_to admin_user_impersonation_tokens_path
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def user
    @user ||= User.find_by!(username: params[:user_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def finder(options = {})
    PersonalAccessTokensFinder.new({ user: user, impersonation: true }.merge(options))
  end

  def impersonation_token_params
    params.require(:personal_access_token).permit(:name, :expires_at, :impersonation, scopes: [])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def set_index_vars
    @scopes = Gitlab::Auth.available_scopes_for(current_user)

    @impersonation_token ||= finder.build
    @inactive_impersonation_tokens = finder(state: 'inactive').execute
    @active_impersonation_tokens = finder(state: 'active').execute.order(:expires_at)

    @new_impersonation_token = PersonalAccessToken.redis_getdel(current_user.id)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
