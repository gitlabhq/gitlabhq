# frozen_string_literal: true

class UserSettings::ActiveSessionsController < Profiles::ApplicationController
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
