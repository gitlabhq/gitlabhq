module Gitlab
  # Module containing GitLab's syntax color scheme definitions and helper
  # methods for accessing them.
  module ColorSchemes
    # Struct class representing a single Scheme
    Scheme = Struct.new(:id, :name, :css_class)

    SCHEMES = [
      Scheme.new(1, 'White',           'white'),
      Scheme.new(2, 'Dark',            'dark'),
      Scheme.new(3, 'Solarized Light', 'solarized-light'),
      Scheme.new(4, 'Solarized Dark',  'solarized-dark'),
      Scheme.new(5, 'Monokai',         'monokai')
    ].freeze

    # Convenience method to get a space-separated String of all the color scheme
    # classes that might be applied to a code block.
    #
    # Returns a String
    def self.body_classes
      SCHEMES.collect(&:css_class).uniq.join(' ')
    end

    # Get a Scheme by its ID
    #
    # If the ID is invalid, returns the default Scheme.
    #
    # id - Integer ID
    #
    # Returns a Scheme
    def self.by_id(id)
      SCHEMES.detect { |s| s.id == id } || default
    end

    # Returns the number of defined Schemes
    def self.count
      SCHEMES.size
    end

    # Get the default Scheme
    #
    # Returns a Scheme
    def self.default
      by_id(1)
    end

    # Iterate through each Scheme
    #
    # Yields the Scheme object
    def self.each(&block)
      SCHEMES.each(&block)
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
  end
end
