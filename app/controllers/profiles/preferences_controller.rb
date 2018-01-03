class Profiles::PreferencesController < Profiles::ApplicationController
  before_action :user

  def show
  end

  def update
    begin
      result = Users::UpdateService.new(current_user, preferences_params.merge(user: user)).execute

      if result[:status] == :success
        flash[:notice] = 'Preferences saved.'
      else
        flash[:alert] = 'Failed to save preferences.'
      end
    rescue ArgumentError => e
      # Raised when `dashboard` is given an invalid value.
      flash[:alert] = "Failed to save preferences (#{e.message})."
    end

    respond_to do |format|
      format.html { redirect_to profile_preferences_path }
      format.js
    end
  end

  private

  def user
    @user = current_user
  end

  def preferences_params
    params.require(:user).permit(
      :color_scheme_id,
      :layout,
      :dashboard,
      :project_view,
      :theme_id
    )
  end
end
