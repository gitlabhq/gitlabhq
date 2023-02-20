# frozen_string_literal: true

module Gitlab
  # Module containing GitLab's syntax color scheme definitions and helper
  # methods for accessing them.
  module ColorSchemes
    # Struct class representing a single Scheme
    Scheme = Struct.new(:id, :name, :css_class)

    def self.available_schemes
      [
        Scheme.new(1, s_('SynthaxHighlightingTheme|Light'),           'white'),
        Scheme.new(2, s_('SynthaxHighlightingTheme|Dark'),            'dark'),
        Scheme.new(3, s_('SynthaxHighlightingTheme|Solarized Light'), 'solarized-light'),
        Scheme.new(4, s_('SynthaxHighlightingTheme|Solarized Dark'),  'solarized-dark'),
        Scheme.new(5, s_('SynthaxHighlightingTheme|Monokai'),         'monokai'),
        Scheme.new(6, s_('SynthaxHighlightingTheme|None'),            'none')
      ]
    end

    # Convenience method to get a space-separated String of all the color scheme
    # classes that might be applied to a code block.
    #
    # Returns a String
    def self.body_classes
      available_schemes.collect(&:css_class).uniq.join(' ')
    end

    # Get a Scheme by its ID
    #
    # If the ID is invalid, returns the default Scheme.
    #
    # id - Integer ID
    #
    # Returns a Scheme
    def self.by_id(id)
      available_schemes.detect { |s| s.id == id } || default
    end

    # Returns the number of defined Schemes
    def self.count
      available_schemes.size
    end

    # Get the default Scheme
    #
    # Returns a Scheme
    def self.default
      by_id(Gitlab::CurrentSettings.default_syntax_highlighting_theme)
    end

    # Iterate through each Scheme
    #
    # Yields the Scheme object
    def self.each(&block)
      available_schemes.each(&block)
    end

    # Get the Scheme for the specified user, or the default
    #
    # user - User record
    #
    # Returns a Scheme
    def self.for_user(user)
      if user
        by_id(user.color_scheme_id)
      else
        default
      end
    end

    def self.valid_ids
      available_schemes.map(&:id)
    end
  end
end
