# Helper methods for per-User preferences
module PreferencesHelper
  # Populates the dashboard preference select field with more user-friendly
  # values.
  def dashboard_choices
    orig = User.dashboards.keys

    choices = [
      ['Your Projects (default)', orig[0]],
      ['Starred Projects',        orig[1]]
    ]

    if orig.size != choices.size
      # Assure that anyone adding new options updates this method too
      raise RuntimeError, "`User` defines #{orig.size} dashboard choices," +
        " but #{__method__} defined #{choices.size}"
    else
      choices
    end
  end
end
