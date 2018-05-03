class Profiles::ActiveSessionsController < Profiles::ApplicationController
  def index
    @sessions = ActiveSession.list(current_user)
  end

  def destroy
    ActiveSession.destroy(current_user, params[:id])

    respond_to do |format|
      format.html { redirect_to profile_active_sessions_url, status: 302 }
      format.js { head :ok }
    end
  end
end
