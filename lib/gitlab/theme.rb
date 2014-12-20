module Gitlab
  class Theme
    BASIC  = 1 unless const_defined?(:BASIC)
    MARS   = 2 unless const_defined?(:MARS)
    MODERN = 3 unless const_defined?(:MODERN)
    GRAY   = 4 unless const_defined?(:GRAY)
    COLOR  = 5 unless const_defined?(:COLOR)

    def self.css_class_by_id(id)
      themes = {
        BASIC  => "ui_basic",
        MARS   => "ui_mars",
        MODERN => "ui_modern",
        GRAY   => "ui_gray",
        COLOR  => "ui_color"
      }

      id ||= Gitlab.config.gitlab.default_theme

      return themes[id]
    end

    def self.type_css_class_by_id(id)
      types = {
        BASIC  => 'light_theme',
        MARS   => 'dark_theme',
        MODERN => 'dark_theme',
        GRAY   => 'dark_theme',
        COLOR  => 'dark_theme'
      }

      id ||= Gitlab.config.gitlab.default_theme

      types[id]
    end
  end
end
