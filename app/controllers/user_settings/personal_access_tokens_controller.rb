# frozen_string_literal: true

module UserSettings
  class PersonalAccessTokensController < ApplicationController
    include RenderAccessTokens

    feature_category :system_access

    before_action :check_personal_access_tokens_enabled

    def index
      set_index_vars
      scopes = params[:scopes].split(',').map(&:squish).select(&:present?).map(&:to_sym) unless params[:scopes].nil?
      @personal_access_token = finder.build(
        name: params[:name],
        scopes: scopes
      )

      respond_to do |format|
        format.html
        format.json do
          render json: @active_access_tokens
        end
      end
    end

    def create
      result = ::PersonalAccessTokens::CreateService.new(
        current_user: current_user,
        target_user: current_user,
        params: personal_access_token_params,
        concatenate_errors: false
      ).execute

      @personal_access_token = result.payload[:personal_access_token]

      if result.success?
        render json: { new_token: @personal_access_token.token,
                       active_access_tokens: active_access_tokens }, status: :ok
      else
        render json: { errors: result.errors }, status: :unprocessable_entity
      end
    end

    def revoke
      @personal_access_token = finder.find(params[:id])
      service = PersonalAccessTokens::RevokeService.new(current_user, token: @personal_access_token).execute
      service.success? ? flash[:notice] = service.message : flash[:alert] = service.message

      redirect_to user_settings_personal_access_tokens_path
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
      @active_access_tokens = active_access_tokens
    end

    def represent(tokens)
      ::PersonalAccessTokenSerializer.new.represent(tokens)
    end

    def check_personal_access_tokens_enabled
      render_404 if Gitlab::CurrentSettings.personal_access_tokens_disabled?
    end
  end
end

UserSettings::PersonalAccessTokensController.prepend_mod
