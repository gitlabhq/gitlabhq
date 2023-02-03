# frozen_string_literal: true

module Gitlab
  module Utils
    # This module is to validate that delegator classes (`SimpleDelegator`) do not
    # accidentally override important logic on the fabricated object.
    module DelegatorOverride
      def delegator_target(target_class)
        return unless Gitlab::Environment.static_verification?

        unless self < ::SimpleDelegator
          raise ArgumentError, "'#{self}' is not a subclass of 'SimpleDelegator' class."
        end

        DelegatorOverride.validator(self).add_target(target_class)
      end

      def delegator_override(*names)
        return unless Gitlab::Environment.static_verification?
        raise TypeError unless names.all?(Symbol)

        DelegatorOverride.validator(self).add_allowlist(names)
      end

      def delegator_override_with(mod)
        return unless Gitlab::Environment.static_verification?
        raise TypeError unless mod.is_a?(Module)

        DelegatorOverride.validator(self).add_allowlist(mod.instance_methods)
      end

      def self.validator(delegator_class)
        validators[delegator_class] ||= Validator.new(delegator_class)
      end

      def self.validators
        @validators ||= {}
      end

      def self.verify!
        validators.each_value do |validator|
          validator.expand_on_ancestors(validators)
          validator.validate_overrides!
        end
      end
    end
  end
end
