module Gitlab
  class Theme
    BASIC  = 1 unless const_defined?(:BASIC)
    MARS   = 2 unless const_defined?(:MARS)
    MODERN = 3 unless const_defined?(:MODERN)
    GRAY   = 4 unless const_defined?(:GRAY)
    COLOR  = 5 unless const_defined?(:COLOR)
    BLUE   = 6 unless const_defined?(:BLUE)

    def self.classes
      @classes ||= {
        BASIC  => 'ui_basic',
        MARS   => 'ui_mars',
        MODERN => 'ui_modern',
        GRAY   => 'ui_gray',
        COLOR  => 'ui_color',
        BLUE   => 'ui_blue'
      }
    end

    def self.css_class_by_id(id)
      id ||= Gitlab.config.gitlab.default_theme
      classes[id]
    end

    def self.types
      @types ||= {
        BASIC  => 'light_theme',
        MARS   => 'dark_theme',
        MODERN => 'dark_theme',
        GRAY   => 'dark_theme',
        COLOR  => 'dark_theme',
        BLUE   => 'light_theme'
      }
    end

    def self.type_css_class_by_id(id)
      id ||= Gitlab.config.gitlab.default_theme
      types[id]
    end

    # Convenience method to get a space-separated String of all the theme
    # classes that might be applied to the `body` element
    #
    # Returns a String
    def self.body_classes
      (classes.values + types.values).uniq.join(' ')
    end
  end
end
