# Helper methods for per-User preferences
module PreferencesHelper
  # Maps `dashboard` values to more user-friendly option text
  DASHBOARD_CHOICES = {
    projects: 'Your Projects (default)',
    stars:    'Starred Projects'
  }.with_indifferent_access.freeze

  # Returns an Array usable by a select field for more user-friendly option text
  def dashboard_choices
    defined = User.dashboards

    if defined.size != DASHBOARD_CHOICES.size
      # Ensure that anyone adding new options updates this method too
      raise RuntimeError, "`User` defines #{defined.size} dashboard choices," +
        " but `DASHBOARD_CHOICES` defined #{DASHBOARD_CHOICES.size}."
    else
      defined.map do |key, _|
        # Use `fetch` so `KeyError` gets raised when a key is missing
        [DASHBOARD_CHOICES.fetch(key), key]
      end
    end
  end

  def project_view_choices
    [
      ['Readme (default)', :readme],
      ['Activity view', :activity]
    ]
  end

  def user_application_theme
    Gitlab::Themes.for_user(current_user).css_class
  end

  def user_color_scheme
    Gitlab::ColorSchemes.for_user(current_user).css_class
  end

  def prefer_readme?
    !current_user ||
      current_user.project_view == 'readme'
  end
end
