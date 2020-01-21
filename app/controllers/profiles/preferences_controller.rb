# frozen_string_literal: true

class Profiles::PreferencesController < Profiles::ApplicationController
  before_action :user

  def show
  end

  def update
    begin
      result = Users::UpdateService.new(current_user, preferences_params.merge(user: user)).execute

      if result[:status] == :success
        flash[:notice] = _('Preferences saved.')
      else
        flash[:alert] = _('Failed to save preferences.')
      end
    rescue ArgumentError => e
      # Raised when `dashboard` is given an invalid value.
      flash[:alert] = _("Failed to save preferences (%{error_message}).") % { error_message: e.message }
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
    params.require(:user).permit(preferences_param_names)
  end

  def preferences_param_names
    [
      :color_scheme_id,
      :layout,
      :dashboard,
      :project_view,
      :theme_id,
      :first_day_of_week,
      :preferred_language,
      :time_display_relative,
      :time_format_in_24h,
      :show_whitespace_in_diffs,
      :sourcegraph_enabled,
      :render_whitespace_in_code
    ]
  end
end

Profiles::PreferencesController.prepend_if_ee('::EE::Profiles::PreferencesController')
