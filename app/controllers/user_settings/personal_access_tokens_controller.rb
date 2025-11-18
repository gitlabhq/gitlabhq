# frozen_string_literal: true

module UserSettings
  class PersonalAccessTokensController < ApplicationController
    include FeedTokenHelper

    feature_category :system_access

    before_action :check_personal_access_tokens_enabled
    before_action only: :index do
      push_frontend_feature_flag(:fine_grained_personal_access_tokens)
    end
    prepend_before_action(only: [:index]) { authenticate_sessionless_user!(:ics) }

    def index
      scopes = []
      unless params[:scopes].nil?
        # An over engineered solution to generate scopes array without extra object allocations
        params[:scopes].split(",", Gitlab::Auth.all_available_scopes.count + 1) do |scope|
          scope = scope.squish
          next if scope.empty?

          scope = scope.to_sym
          next if Gitlab::Auth.all_available_scopes.exclude?(scope)

          scopes << scope
        end
      end

      @access_token_params = {
        name: params[:name],
        description: params[:description],
        scopes: scopes
      }

      respond_to do |format|
        format.html
        format.ics do
          if params[:feed_token]
            response.headers['Content-Type'] = 'text/plain'
            render plain: expiry_ics
          else
            redirect_to "#{request.path}?feed_token=#{generate_feed_token_with_path(:ics, request.path)}"
          end
        end
      end
    end

    def new
      render_404 unless Feature.enabled?(:fine_grained_personal_access_tokens, :instance)
    end

    def create
      result = ::PersonalAccessTokens::CreateService.new(
        current_user: current_user,
        target_user: current_user,
        organization_id: Current.organization.id,
        params: personal_access_token_params,
        concatenate_errors: false
      ).execute

      if result.success?
        render json: { token: result.payload[:personal_access_token].token }, status: :ok
      else
        render json: { errors: result.errors }, status: :unprocessable_entity
      end
    end

    def toggle_dpop
      unless Feature.enabled?(:dpop_authentication, current_user)
        redirect_to user_settings_personal_access_tokens_path
        return
      end

      result = UserPreferences::UpdateService.new(current_user, dpop_params).execute

      if result.success?
        flash[:notice] = _('DPoP preference updated.')
      else
        flash[:warning] = _('Unable to update DPoP preference.')
      end

      redirect_to user_settings_personal_access_tokens_path
    end

    private

    def expiry_ics
      tokens =
        PersonalAccessTokensFinder.new({ user: current_user, impersonation: false, state: 'active',
                                         sort: 'expires_asc' }).execute.preload_users
      cal = Icalendar::Calendar.new
      tokens.each do |token|
        next unless token.expires_at

        cal.event do |event|
          event.dtstart = Icalendar::Values::Date.new(token.expires_at)
          event.dtend = Icalendar::Values::Date.new(token.expires_at)
          event.summary = format(_("Token '%{name}' expires today"), name: token.name)
        end
      end
      cal.to_ical
    end

    def personal_access_token_params
      params.require(:personal_access_token).permit(:name, :expires_at, :description, scopes: [])
    end

    def dpop_params
      params.require(:user).permit(:dpop_enabled)
    end

    def check_personal_access_tokens_enabled
      render_404 if Gitlab::CurrentSettings.personal_access_tokens_disabled?
    end
  end
end

UserSettings::PersonalAccessTokensController.prepend_mod
