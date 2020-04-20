# frozen_string_literal: true

# Helper methods for per-User preferences
module PreferencesHelper
  def layout_choices
    [
        ['Fixed', :fixed],
        ['Fluid', :fluid]
    ]
  end

  # Returns an Array usable by a select field for more user-friendly option text
  def dashboard_choices
    dashboards = User.dashboards.keys

    validate_dashboard_choices!(dashboards)
    dashboards -= excluded_dashboard_choices

    dashboards.map do |key|
      # Use `fetch` so `KeyError` gets raised when a key is missing
      [localized_dashboard_choices.fetch(key), key]
    end
  end

  # Maps `dashboard` values to more user-friendly option text
  def localized_dashboard_choices
    {
      projects: _("Your Projects (default)"),
      stars:    _("Starred Projects"),
      project_activity: _("Your Projects' Activity"),
      starred_project_activity: _("Starred Projects' Activity"),
      groups: _("Your Groups"),
      todos: _("Your To-Do List"),
      issues: _("Assigned Issues"),
      merge_requests: _("Assigned Merge Requests"),
      operations: _("Operations Dashboard")
    }.with_indifferent_access.freeze
  end

  def project_view_choices
    [
      ['Files and Readme (default)', :files],
      ['Activity', :activity],
      ['Readme', :readme]
    ]
  end

  def first_day_of_week_choices
    [
      [_('Sunday'), 0],
      [_('Monday'), 1],
      [_('Saturday'), 6]
    ]
  end

  def first_day_of_week_choices_with_default
    first_day_of_week_choices.unshift([_('System default (%{default})') % { default: default_first_day_of_week }, nil])
  end

  def user_application_theme
    @user_application_theme ||= Gitlab::Themes.for_user(current_user).css_class
  end

  def user_color_scheme
    Gitlab::ColorSchemes.for_user(current_user).css_class
  end

  def user_tab_width
    Gitlab::TabWidth.css_class_for_user(current_user)
  end

  def language_choices
    Gitlab::I18n::AVAILABLE_LANGUAGES.map { |value, label| [label, value] }
  end

  private

  # Ensure that anyone adding new options updates `DASHBOARD_CHOICES` too
  def validate_dashboard_choices!(user_dashboards)
    if user_dashboards.size != localized_dashboard_choices.size
      raise "`User` defines #{user_dashboards.size} dashboard choices," \
        " but `localized_dashboard_choices` defined #{localized_dashboard_choices.size}."
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
end

PreferencesHelper.prepend_if_ee('EE::PreferencesHelper')
