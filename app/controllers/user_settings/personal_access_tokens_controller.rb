# frozen_string_literal: true

module UserSettings
  class PersonalAccessTokensController < ApplicationController
    include RenderAccessTokens
    include FeedTokenHelper

    feature_category :system_access

    before_action :check_personal_access_tokens_enabled
    before_action do
      push_frontend_feature_flag(:pat_ip, current_user)
    end
    prepend_before_action(only: [:index]) { authenticate_sessionless_user!(:ics) }

    def index
      set_index_vars
      scopes = params[:scopes].split(',').map(&:squish).select(&:present?).map(&:to_sym) unless params[:scopes].nil?
      @personal_access_token = finder.build(
        name: params[:name],
        description: params[:description],
        scopes: scopes
      )

      respond_to do |format|
        format.html
        format.json do
          render json: @active_access_tokens
        end
        format.ics do
          if params[:feed_token]
            response.headers['Content-Type'] = 'text/plain'
            render plain: expiry_ics(@active_access_tokens)
          else
            redirect_to "#{request.path}?feed_token=#{generate_feed_token_with_path(:ics, request.path)}"
          end
        end
      end
    end

    def create
      result = ::PersonalAccessTokens::CreateService.new(
        current_user: current_user,
        target_user: current_user,
        organization_id: Current.organization_id,
        params: personal_access_token_params,
        concatenate_errors: false
      ).execute

      @personal_access_token = result.payload[:personal_access_token]

      if result.success?
        tokens, size = active_access_tokens
        render json: { new_token: @personal_access_token.token,
                       active_access_tokens: tokens, total: size }, status: :ok
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

    def rotate
      token = finder.find(params[:id])
      result = PersonalAccessTokens::RotateService.new(current_user, token, nil, keep_token_lifetime: true).execute

      @personal_access_token = result.payload[:personal_access_token]
      if result.success?
        tokens, size = active_access_tokens
        render json: { new_token: @personal_access_token.token,
                       active_access_tokens: tokens, total: size }, status: :ok
      else
        render json: { message: result.message }, status: :unprocessable_entity
      end
    end

    private

    def finder(options = {})
      PersonalAccessTokensFinder.new({ user: current_user, impersonation: false }.merge(options))
    end

    def personal_access_token_params
      params.require(:personal_access_token).permit(:name, :expires_at, :description, scopes: [])
    end

    def set_index_vars
      @scopes = Gitlab::Auth.available_scopes_for(current_user)
      @active_access_tokens, @active_access_tokens_size = active_access_tokens
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
