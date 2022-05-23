# frozen_string_literal: true

class Profiles::PersonalAccessTokensController < Profiles::ApplicationController
  feature_category :authentication_and_authorization

  before_action do
    push_frontend_feature_flag(:personal_access_tokens_scoped_to_projects, current_user)
  end

  def index
    set_index_vars
    scopes = params[:scopes].split(',').map(&:squish).select(&:present?).map(&:to_sym) unless params[:scopes].nil?
    @personal_access_token = finder.build(
      name: params[:name],
      scopes: scopes
    )
  end

  def create
    result = ::PersonalAccessTokens::CreateService.new(
      current_user: current_user, target_user: current_user, params: personal_access_token_params
    ).execute

    @personal_access_token = result.payload[:personal_access_token]

    if Feature.enabled?(:access_token_ajax)
      if result.success?
        render json: { new_token: @personal_access_token.token,
                       active_access_tokens: active_personal_access_tokens }, status: :ok
      else
        render json: { errors: result.errors }, status: :unprocessable_entity
      end
    else
      if result.success?
        PersonalAccessToken.redis_store!(current_user.id, @personal_access_token.token)
        redirect_to profile_personal_access_tokens_path, notice: _("Your new personal access token has been created.")
      else
        set_index_vars
        render :index
      end
    end
  end

  def revoke
    @personal_access_token = finder.find(params[:id])
    service = PersonalAccessTokens::RevokeService.new(current_user, token: @personal_access_token).execute
    service.success? ? flash[:notice] = service.message : flash[:alert] = service.message

    redirect_to profile_personal_access_tokens_path
  end

  private

  def finder(options = {})
    PersonalAccessTokensFinder.new({ user: current_user, impersonation: false }.merge(options))
  end

  def personal_access_token_params
    params.require(:personal_access_token).permit(:name, :expires_at, scopes: [])
  end

  def set_index_vars
    @scopes = Gitlab::Auth.available_scopes_for(current_user)
    @active_personal_access_tokens = active_personal_access_tokens

    if Feature.disabled?(:access_token_ajax)
      @new_personal_access_token = PersonalAccessToken.redis_getdel(current_user.id)
    end
  end

  def active_personal_access_tokens
    tokens = finder(state: 'active', sort: 'expires_at_asc').execute

    if Feature.enabled?(:access_token_ajax)
      ::API::Entities::PersonalAccessTokenWithDetails.represent(tokens)
    else
      tokens
    end
  end
end
