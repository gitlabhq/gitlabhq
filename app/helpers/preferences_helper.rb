# frozen_string_literal: true

# Helper methods for per-User preferences
module PreferencesHelper
  def layout_choices
    [
      [s_('Layout|Fixed'), :fixed],
      [s_('Layout|Fluid'), :fluid]
    ]
  end

  def dashboard_value
    # For homepage rollout with flipped mapping, show the effective preference
    # that matches what they actually see, not the raw database value
    if current_user.should_use_flipped_dashboard_mapping_for_rollout?
      current_user.effective_dashboard_for_routing
    else
      current_user.dashboard
    end
  end

  # Returns an Array usable by a select field for more user-friendly option text
  def dashboard_choices
    dashboards = User.dashboards.keys

    validate_dashboard_choices!(dashboards)
    dashboards -= excluded_dashboard_choices

    dashboards -= ['homepage'] unless Feature.enabled?(:personal_homepage, current_user)

    # Move homepage to first position if it's available
    # For homepage rollout with flipped mapping, homepage becomes their default (value 0)
    dashboards.unshift('homepage') if dashboards.delete('homepage')

    dashboards.map do |key|
      {
        # Use `fetch` so `KeyError` gets raised when a key is missing
        text: localized_dashboard_choices_for_user.fetch(key),
        value: key
      }
    end
  end

  # Maps `dashboard` values to more user-friendly option text for current user
  def localized_dashboard_choices_for_user
    return localized_dashboard_choices unless current_user.should_use_flipped_dashboard_mapping_for_rollout?

    localized_dashboard_choices.dup.tap do |choices|
      choices[:projects] = _("Your Contributed Projects")
      choices[:homepage] = _("Personal homepage (default)")
    end.freeze
  end

  # Maps `dashboard` values to more user-friendly option text
  def localized_dashboard_choices
    {
      projects: _("Your Contributed Projects (default)"),
      stars: _("Starred Projects"),
      member_projects: _("Member Projects"),
      your_activity: _("Your Activity"),
      project_activity: _("Your Projects' Activity"),
      starred_project_activity: _("Starred Projects' Activity"),
      followed_user_activity: _("Followed Users' Activity"),
      groups: _("Your Groups"),
      todos: _("Your To-Do List"),
      issues: _("Assigned issues"),
      merge_requests: _("Merge request homepage"),
      operations: _("Operations Dashboard"),
      homepage: _("Personal homepage"),
      assigned_merge_requests: _("Assigned merge requests"),
      review_merge_requests: _("Merge request reviews")
    }.compact.with_indifferent_access.freeze
  end

  def project_view_choices
    [
      [s_('ProjectView|Files and Readme (default)'), :files],
      [s_('ProjectView|Activity'), :activity],
      [s_('ProjectView|Readme'), :readme],
      [s_('ProjectView|Wiki'), :wiki]
    ]
  end

  def first_day_of_week_choices
    [
      [_('Sunday'), 0],
      [_('Monday'), 1],
      [_('Saturday'), 6]
    ]
  end

  def time_display_format_choices
    UserPreference.time_display_formats
  end

  def first_day_of_week_choices_with_default
    first_day_of_week_choices.unshift([_('System default (%{default})') % { default: default_first_day_of_week }, nil])
  end

  def user_application_theme
    @user_application_theme ||= Gitlab::Themes.for_user(current_user).css_class
  end

  def user_application_color_mode
    @user_color_mode ||= Gitlab::ColorModes.for_user(current_user).css_class
  end

  def user_application_light_mode?
    user_application_color_mode == 'gl-light'
  end

  def user_application_dark_mode?
    user_application_color_mode == 'gl-dark'
  end

  def user_application_system_mode?
    user_application_color_mode == 'gl-system'
  end

  def user_theme_primary_color
    Gitlab::Themes.for_user(current_user).primary_color
  end

  def user_color_scheme
    Gitlab::ColorSchemes.for_user(current_user).css_class
  end

  def user_light_color_scheme
    Gitlab::ColorSchemes.light_for_user(current_user).css_class
  end

  def user_dark_color_scheme
    Gitlab::ColorSchemes.dark_for_user(current_user).css_class
  end

  def user_tab_width
    Gitlab::TabWidth.css_class_for_user(current_user)
  end

  def user_diffs_colors
    {
      deletion: current_user&.diffs_deletion_color.presence,
      addition: current_user&.diffs_addition_color.presence
    }.compact
  end

  def custom_diff_color_classes
    return if request.path == profile_preferences_path

    classes = []
    classes << 'diff-custom-addition-color' if current_user&.diffs_addition_color.presence
    classes << 'diff-custom-deletion-color' if current_user&.diffs_deletion_color.presence
    classes
  end

  def language_choices
    selectable_locales_with_translation_level(Gitlab::I18n::MINIMUM_TRANSLATION_LEVEL).sort.map do |lang, key|
      {
        text: lang,
        value: key
      }
    end
  end

  def default_preferred_language_choices
    options_for_select(
      selectable_locales_with_translation_level(
        PreferredLanguageSwitcherHelper::SWITCHER_MINIMUM_TRANSLATION_LEVEL).sort,
      Gitlab::CurrentSettings.default_preferred_language
    )
  end

  def integration_views
    [].tap do |views|
      if Gitlab::CurrentSettings.gitpod_enabled
        views << {
          name: 'gitpod',
          message: gitpod_enable_description,
          message_url: gitpod_url_placeholder,
          help_link: help_page_path('integration/gitpod.md')
        }
      end

      if Gitlab::CurrentSettings.sourcegraph_enabled
        views << {
          name: 'sourcegraph',
          message: sourcegraph_url_message,
          message_url: Gitlab::CurrentSettings.sourcegraph_url,
          help_link: help_page_path(
            'user/profile/preferences.md',
            anchor: 'integrate-your-gitlab-instance-with-sourcegraph'
          )
        }
      end

      views << extensions_marketplace_view
    end.compact
  end

  private

  def extensions_marketplace_view
    return unless WebIde::ExtensionMarketplace.feature_enabled_from_application_settings?

    build_extensions_marketplace_view(
      title: s_("Preferences|Web IDE"),
      message: s_(
        "PreferencesIntegrations|Uses %{extensions_marketplace_home} as the extension marketplace for the Web IDE.")
    )
  end

  def build_extensions_marketplace_view(title:, message:)
    marketplace_home_url = ::WebIde::ExtensionMarketplace.marketplace_home_url(user: current_user)

    extensions_marketplace_home = "%{linkStart}#{marketplace_home_url}%{linkEnd}"
    {
      name: 'extensions_marketplace',
      message: format(message, extensions_marketplace_home: extensions_marketplace_home),
      title: title,
      message_url: marketplace_home_url,
      help_link: WebIde::ExtensionMarketplace.help_preferences_url
    }
  end

  def gitpod_url_placeholder
    Gitlab::CurrentSettings.gitpod_url.presence || 'https://app.ona.com/'
  end

  # Ensure that anyone adding new options updates `localized_dashboard_choices` too
  def validate_dashboard_choices!(user_dashboards)
    if user_dashboards.size != localized_dashboard_choices.size
      raise "`User` defines #{user_dashboards.size} dashboard choices, " \
        "but `localized_dashboard_choices` defined #{localized_dashboard_choices.size}."
    end
  end

  # List of dashboard choice to be excluded from CE.
  # EE would override this.
  def excluded_dashboard_choices
    ['operations']
  end

  def default_first_day_of_week
    first_day_of_week_choices.rassoc(Gitlab::CurrentSettings.first_day_of_week).first
  end

  def selectable_locales_with_translation_level(minimum_level)
    Gitlab::I18n.selectable_locales(minimum_level).map do |code, language|
      [
        s_("i18n|%{language} (%{percent_translated}%% translated)") % {
          language: language,
          percent_translated: Gitlab::I18n.percentage_translated_for(code)
        },
        code
      ]
    end
  end
end

PreferencesHelper.prepend_mod_with('PreferencesHelper')
