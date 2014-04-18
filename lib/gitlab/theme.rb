module Gitlab
  class Theme
    BASIC  = 1
    MARS   = 2
    MODERN = 3
    GRAY   = 4
    COLOR  = 5

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
  end
end
