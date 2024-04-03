# frozen_string_literal: true

module UserSettings
  class ActiveSessionsController < ApplicationController
    feature_category :system_access

    def index
      @sessions = ActiveSession.list(current_user).reject(&:is_impersonated)
    end

    def destroy
      # params[:id] can be an Rack::Session::SessionId#private_id
      ActiveSession.destroy_session(current_user, params[:id])
      current_user.forget_me!

      respond_to do |format|
        format.html { redirect_to user_settings_active_sessions_url, status: :found }
        format.js { head :ok }
      end
    end
  end
end

UserSettings::ActiveSessionsController.prepend_mod
