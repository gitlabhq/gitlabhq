# frozen_string_literal: true

# Extending this module will give you the ability of defining
# enum values in a declarative way.
#
#   module DismissalReasons
#     extend DeclarativeEnum
#
#     key  :dismissal_reason
#     name 'DismissalReasonOfVulnerability'
#
#     description <<~TEXT
#       This enum holds the user selected dismissal reason
#       when they are dismissing the vulnerabilities
#     TEXT
#
#     define do
#       acceptable_risk value: 0, description: N_('The vulnerability is known but is considered to be an acceptable business risk.')
#       false_positive value: 1, description: N_('An error in reporting the presence of a vulnerability in a system when the vulnerability is not present.')
#       used_in_tests value: 2, description: N_('The finding is not a vulnerability because it is part of a test or is test data.')
#     end
#
# Then we can use this module to register enums for our Active Record models like so,
#
#   class VulnerabilityFeedback
#     declarative_enum DismissalReasons
#   end
#
# Also we can use this module to create GraphQL Enum types like so,
#
# module Types
#   module Vulnerabilities
#     class DismissalReasonEnum < BaseEnum
#       declarative_enum DismissalReasons
#     end
#   end
# end
#
# rubocop:disable Gitlab/ModuleWithInstanceVariables
module DeclarativeEnum
  # This `prepended` hook will merge the enum definition
  # of the prepended module into the base module to be
  # used by `prepend_mod_with` helper method.
  def prepended(base)
    base.definition.merge!(definition)
  end

  def key(new_key = nil)
    @key = new_key if new_key

    @key
  end

  def name(new_name = nil)
    @name = new_name if new_name

    @name
  end

  def description(new_description = nil)
    @description = new_description if new_description

    @description
  end

  def values
    definition.transform_values { |definition| definition[:value] }
  end

  # Return list of dynamically translated descriptions.
  #
  # It is required to define descriptions with `N_(...)`.
  #
  # See https://github.com/grosser/fast_gettext#n_-and-nn_-make-dynamic-translations-available-to-the-parser
  def translated_descriptions
    definition.transform_values { |definition| _(definition[:description]) }
  end

  def define(&block)
    raise LocalJumpError, 'No block given' unless block

    @definition = Builder.new(definition, block).build
  end

  # We can use this method later to apply some sanity checks
  # but for now, returning a Hash without any check is enough.
  def definition
    @definition.to_h
  end

  class Builder
    KeyCollisionError = Class.new(StandardError)

    def initialize(definition, block)
      @definition = definition
      @block = block
    end

    def build
      instance_exec(&@block)

      @definition
    end

    private

    def method_missing(name, *arguments, value: nil, description: nil, &block)
      key = name.downcase.to_sym
      raise KeyCollisionError, "'#{key}' collides with an existing enum key!" if @definition[key]

      @definition[key] = {
        value: value,
        description: description
      }
    end
  end
end
# rubocop:enable Gitlab/ModuleWithInstanceVariables
