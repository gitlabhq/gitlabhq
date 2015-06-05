# Helper methods for per-User preferences
module PreferencesHelper
  COLOR_SCHEMES = {
    1 => 'white',
    2 => 'dark',
    3 => 'solarized-light',
    4 => 'solarized-dark',
    5 => 'monokai',
  }
  COLOR_SCHEMES.default = 'white'

  # Helper method to access the COLOR_SCHEMES
  #
  # The keys are the `color_scheme_ids`
  # The values are the `name` of the scheme.
  #
  # The preview images are `name-scheme-preview.png`
  # The stylesheets should use the css class `.name`
  def color_schemes
    COLOR_SCHEMES.freeze
  end

  def user_application_theme
    theme = Gitlab::Themes.by_id(current_user.try(:theme_id))
    theme.css_class
  end

  def user_color_scheme_class
    COLOR_SCHEMES[current_user.try(:color_scheme_id)] if defined?(current_user)
  end
end
