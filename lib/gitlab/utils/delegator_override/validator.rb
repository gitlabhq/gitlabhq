# frozen_string_literal: true

module Gitlab
  module Utils
    module DelegatorOverride
      class Validator
        UnexpectedDelegatorOverrideError = Class.new(StandardError)

        attr_reader :delegator_class, :target_classes

        OVERRIDE_ERROR_MESSAGE = <<~EOS
          We've detected that the delegator is overriding a specific method(s) on the target class.
          Please make sure if it's intentional and handle this error accordingly.
          See https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/presenters/README.md#validate-accidental-overrides for more information.
        EOS

        def initialize(delegator_class)
          @delegator_class = delegator_class
          @target_classes = []
        end

        def add_allowlist(names)
          allowed_method_names.concat(names)
        end

        def allowed_method_names
          @allowed_method_names ||= []
        end

        def add_target(target_class)
          return unless target_class

          @target_classes << target_class

          # Also include all descendants inheriting from the target,
          # to make sure we catch methods that are only defined in some of them.
          @target_classes += target_class.descendants
        end

        # This will make sure allowlist we put into ancestors are all included
        def expand_on_ancestors(validators)
          delegator_class.ancestors.each do |ancestor|
            next if delegator_class == ancestor # ancestor includes itself

            validator_ancestor = validators[ancestor]

            next unless validator_ancestor

            add_allowlist(validator_ancestor.allowed_method_names)
          end
        end

        def validate_overrides!
          return if target_classes.empty?

          errors = []

          # Workaround to fully load the instance methods in the target class.
          # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/69823#note_678887402
          begin
            target_classes.map(&:new)
          rescue ArgumentError
            # Some models might raise ArgumentError here, but it's fine in this case,
            # because this is enough to force ActiveRecord to generate the methods we
            # need to verify, so it's safe to ignore it.
          end

          (delegator_class.instance_methods - allowlist).each do |method_name|
            target_classes.each do |target_class|
              next unless target_class.method_defined?(method_name)

              errors << generate_error(method_name, target_class, delegator_class)
            end
          end

          return if errors.empty?

          details = errors.map { |error| "- #{error}" }.join("\n")

          raise UnexpectedDelegatorOverrideError,
            <<~TEXT
              #{OVERRIDE_ERROR_MESSAGE}
              Here are the conflict details.

              #{details}
            TEXT
        end

        private

        def generate_error(method_name, target_class, delegator_class)
          target_location = extract_location(target_class, method_name)
          delegator_location = extract_location(delegator_class, method_name)
          Error.new(method_name, target_class, target_location, delegator_class, delegator_location)
        end

        def extract_location(klass, method_name)
          klass.instance_method(method_name).source_location&.join(':') || 'unknown'
        end

        def allowlist
          [].tap do |allowed|
            allowed.concat(allowed_method_names)
            allowed.concat(Object.instance_methods)
            allowed.concat(::Delegator.instance_methods)
          end
        end
      end
    end
  end
end
