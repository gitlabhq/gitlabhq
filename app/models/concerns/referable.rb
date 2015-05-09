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
  end

  private

  # Check if a reference is being done cross-project
  #
  # from_project - Refering Project object
  def cross_project_reference?(from_project)
    if Project === self
      self != from_project
    else
      from_project && project && project != from_project
    end
  end
end
