# frozen_string_literal: true

class Profiles::ActiveSessionsController < Profiles::ApplicationController
  def index
    @sessions = ActiveSession.list(current_user).reject(&:is_impersonated)
  end

  def destroy
    ActiveSession.destroy_with_public_id(current_user, params[:id])

    respond_to do |format|
      format.html { redirect_to profile_active_sessions_url, status: :found }
      format.js { head :ok }
    end
  end
end
