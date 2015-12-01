# == Referable concern
#
# Contains functionality related to making a model referable in Markdown, such
# as "#1", "!2", "~3", etc.
module Referable
  extend ActiveSupport::Concern

  # Returns the String necessary to reference this object in Markdown
  #
  # from_project - Refering Project object
  #
  # This should be overridden by the including class.
  #
  # Examples:
  #
  #   Issue.first.to_reference               # => "#1"
  #   Issue.last.to_reference(other_project) # => "cross-project#1"
  #
  # Returns a String
  def to_reference(_from_project = nil)
    ''
  end

  def reference_link_text(from_project = nil)
    to_reference(from_project)
  end

  module ClassMethods
    # The character that prefixes the actual reference identifier
    #
    # This should be overridden by the including class.
    #
    # Examples:
    #
    #   Issue.reference_prefix        # => '#'
    #   MergeRequest.reference_prefix # => '!'
    #
    # Returns a String
    def reference_prefix
      ''
    end

    # Regexp pattern used to match references to this object
    #
    # This must be overridden by the including class.
    #
    # Returns a Regexp
    def reference_pattern
      raise NotImplementedError, "#{self} does not implement #{__method__}"
    end

    def link_reference_pattern(route, pattern)
      %r{
        (?<url>
          #{Regexp.escape(Gitlab.config.gitlab.url)}
          \/#{Project.reference_pattern}
          \/#{Regexp.escape(route)}
          \/#{pattern}
          (?<path>
            (\/[a-z0-9_=-]+)*
          )?
          (?<query>
            \?[a-z0-9_=-]+
            (&[a-z0-9_=-]+)*
          )?
          (?<anchor>\#[a-z0-9_-]+)?
        )
      }x
    end
  end

  private

  # Check if a reference is being done cross-project
  #
  # from_project - Refering Project object
  def cross_project_reference?(from_project)
    if self.is_a?(Project)
      self != from_project
    else
      from_project && self.project && self.project != from_project
    end
  end
end
