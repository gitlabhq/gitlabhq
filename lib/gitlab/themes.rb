module Gitlab
  # Module containing GitLab's application theme definitions and helper methods
  # for accessing them.
  module Themes
    # Theme ID used when no `default_theme` configuration setting is provided.
    APPLICATION_DEFAULT = 2

    # Struct class representing a single Theme
    Theme = Struct.new(:id, :name, :css_class)

    # All available Themes
    THEMES = [
      Theme.new(1, 'Graphite', 'ui_graphite'),
      Theme.new(2, 'Charcoal', 'ui_charcoal'),
      Theme.new(3, 'Green',    'ui_green'),
      Theme.new(4, 'Gray',     'ui_gray'),
      Theme.new(5, 'Violet',   'ui_violet'),
      Theme.new(6, 'Blue',     'ui_blue')
    ].freeze

    # Convenience method to get a space-separated String of all the theme
    # classes that might be applied to the `body` element
    #
    # Returns a String
    def self.body_classes
      THEMES.collect(&:css_class).uniq.join(' ')
    end

    # Get a Theme by its ID
    #
    # If the ID is invalid, returns the default Theme.
    #
    # id - Integer ID
    #
    # Returns a Theme
    def self.by_id(id)
      THEMES.detect { |t| t.id == id } || default
    end

    # Returns the number of defined Themes
    def self.count
      THEMES.size
    end

    # Get the default Theme
    #
    # Returns a Theme
    def self.default
      by_id(default_id)
    end

    # Iterate through each Theme
    #
    # Yields the Theme object
    def self.each(&block)
      THEMES.each(&block)
    end

    # Get the Theme for the specified user, or the default
    #
    # user - User record
    #
    # Returns a Theme
    def self.for_user(user)
      if user
        by_id(user.theme_id)
      else
        default
      end
    end

    private

    def self.default_id
      id = Gitlab.config.gitlab.default_theme.to_i

      # Prevent an invalid configuration setting from causing an infinite loop
      if id < THEMES.first.id || id > THEMES.last.id
        APPLICATION_DEFAULT
      else
        id
      end
    end
  end
end
