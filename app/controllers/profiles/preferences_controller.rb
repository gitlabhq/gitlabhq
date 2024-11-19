# frozen_string_literal: true

class Profiles::PreferencesController < Profiles::ApplicationController
  before_action :user

  feature_category :user_profile

  urgency :low, [:show]
  urgency :medium, [:update]

  def show; end

  def update
    result = Users::UpdateService.new(current_user, preferences_params.merge(user: user)).execute
    if result[:status] == :success
      message = _('Preferences saved.')

      render json: { type: :notice, message: message }
    else
      render status: :bad_request, json: { type: :alert, message: _('Failed to save preferences.') }
    end
  rescue ArgumentError => e
    # Raised when `dashboard` is given an invalid value.
    message = _("Failed to save preferences (%{error_message}).") % { error_message: e.message }
    render status: :bad_request, json: { type: :alert, message: message }
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
      :color_mode_id,
      :diffs_deletion_color,
      :diffs_addition_color,
      :home_organization_id,
      :layout,
      :dashboard,
      :project_view,
      :theme_id,
      :first_day_of_week,
      :preferred_language,
      :time_display_relative,
      :time_display_format,
      :show_whitespace_in_diffs,
      :view_diffs_file_by_file,
      :tab_width,
      :sourcegraph_enabled,
      :gitpod_enabled,
      :extensions_marketplace_enabled,
      :render_whitespace_in_code,
      :project_shortcut_buttons,
      :keyboard_shortcuts_enabled,
      :markdown_surround_selection,
      :markdown_automatic_lists,
      :use_new_navigation,
      :enabled_following,
      :use_work_items_view,
      :text_editor
    ]
  end
end

Profiles::PreferencesController.prepend_mod_with('Profiles::PreferencesController')
