class Profiles::PreferencesController < Profiles::ApplicationController
  before_action :user

  def show
  end

  def update
    if @user.update_attributes(preferences_params)
      flash[:notice] = 'Preferences saved.'
    else
      # TODO (rspeicher): There's no validation on these values, so can it fail?
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
      :theme_id
    )
  end
end
