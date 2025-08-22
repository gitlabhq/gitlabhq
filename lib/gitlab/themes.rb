# frozen_string_literal: true

module Gitlab
  # Module containing GitLab's application theme definitions and helper methods
  # for accessing them.
  module Themes
    extend self

    # Theme ID used when no `default_theme` configuration setting is provided.
    APPLICATION_DEFAULT = 3

    # Theme IDs previously used
    DEPRECATED_THEME_IDS = [
      6, # Light indigo
      7, # Light blue
      8, # Light green
      10, # Light red
      11 # Dark mode theme
    ].freeze

    # Struct class representing a single Theme
    Theme = Struct.new(:id, :name, :css_class, :primary_color)

    # All available Themes
    def available_themes
      [
        Theme.new(3, s_('NavigationTheme|Default'), 'ui-neutral', '#ececef'),
        Theme.new(1, s_('NavigationTheme|Indigo'), 'ui-indigo', '#222261'),
        Theme.new(4, s_('NavigationTheme|Blue'), 'ui-blue', '#0b2640'),
        Theme.new(5, s_('NavigationTheme|Green'), 'ui-green', '#0e4328'),
        Theme.new(9, s_('NavigationTheme|Red'), 'ui-red', '#580d02'),
        Theme.new(2, s_('NavigationTheme|Gray'), 'ui-gray', '#28272d')
      ]
    end

    # Convenience method to get a space-separated String of all the theme
    # classes that might be applied to the `body` element
    #
    # Returns a String
    def body_classes
      available_themes.collect(&:css_class).uniq.join(' ')
    end

    # Maps deprecated light themes to their default counterpart
    def map_deprecated_themes
      {
        # Light indigo to indigo
        6 => 1,
        # Light blue to blue
        7 => 4,
        # Light green to green
        8 => 5,
        # Light red to red
        10 => 9
      }
    end

    # Get a Theme by its ID
    #
    # If the ID is invalid, returns the default Theme.
    #
    # id - Integer ID
    #
    # Returns a Theme
    def by_id(id)
      # Map deprecated IDs to new values
      mapped_id = map_deprecated_themes[id] || id

      available_themes.detect { |t| t.id == mapped_id } || default
    end

    # Returns the number of defined Themes
    def count
      available_themes.size
    end

    # Get the default Theme
    #
    # Returns a Theme
    def default
      by_id(default_id)
    end

    # Iterate through each Theme
    #
    # Yields the Theme object
    def each(&block)
      available_themes.each(&block)
    end

    # Get the Theme for the specified user, or the default
    #
    # user - User record
    #
    # Returns a Theme
    def for_user(user)
      if user
        by_id(user.theme_id)
      else
        default
      end
    end

    def self.valid_ids
      available_themes.map(&:id) + DEPRECATED_THEME_IDS
    end

    private

    def default_id
      @default_id ||= begin
        id = Gitlab.config.gitlab.default_theme.to_i
        theme_ids = available_themes.map(&:id)

        theme_ids.include?(id) ? id : APPLICATION_DEFAULT
      end
    end
  end
end
