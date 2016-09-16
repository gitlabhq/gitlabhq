# Helper methods for per-User preferences
module PreferencesHelper
  def layout_choices
    [
        ['Fixed', :fixed],
        ['Fluid', :fluid]
    ]
  end

  # Maps `dashboard` values to more user-friendly option text
  DASHBOARD_CHOICES = {
    projects: 'Your Projects (default)',
    stars:    'Starred Projects',
    project_activity: "Your Projects' Activity",
    starred_project_activity: "Starred Projects' Activity",
    groups: "Your Groups",
    todos: "Your Todos"
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
      ['Activity view', :activity],
      ['Files view', :files]
    ]
  end

  def user_application_theme
    Gitlab::Themes.for_user(current_user).css_class
  end

  def user_color_scheme
    Gitlab::ColorSchemes.for_user(current_user).css_class
  end

  def default_project_view
    return 'readme' unless current_user

    user_view = current_user.project_view

    if @project.feature_available?(:repository, current_user)
      user_view
    elsif user_view == "activity"
      "activity"
    elsif @project.wiki_enabled?
      "wiki"
    elsif @project.feature_available?(:issues, current_user)
      "projects/issues/issues"
    else
      "customize_workflow"
    end
  end
end
