# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # The first argument to `Feature.enabled?` and `Feature.disabled?` should be a literal symbol.
      # Dynamic keys are discouraged because they are harder to explicitly search for in the codebase by name.
      # Strings are similarly discouraged to simplify exact matching when searching for flag usage.
      #
      # Feature flags are technical debt (should be short lived), so it is important to ensure we can find all usages in
      # order to remove the flag safely.
      # More information at https://docs.gitlab.com/development/feature_flags/#feature-flag-definition-and-validation
      #
      # @example
      #
      #   # bad
      #   Feature.enabled?('some_flag')
      #   Feature.enabled?(flag_name)
      #   Feature.disabled?(flag)
      #
      #   # good
      #   Feature.enabled?(:some_flag)
      #   Feature.disabled?(:other_flag)
      class FeatureFlagKeyDynamic < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'First argument to `Feature.%<method>s` must be a literal symbol.'

        FEATURE_METHODS = %i[enabled? disabled?].freeze

        # @!method feature_flag_method?(node)
        def_node_matcher :feature_flag_method?, <<~PATTERN
            (send
              (const nil? :Feature)
              ${:enabled? :disabled?}
              ...
            )
        PATTERN

        def on_send(node)
          method_name = feature_flag_method?(node)
          return unless method_name

          first_arg = node.first_argument
          return if first_arg&.sym_type?

          message = format(MSG, method: method_name)

          add_offense(first_arg, message: message) do |corrector|
            autocorrect(corrector, first_arg) if first_arg&.str_type?
          end
        end
        alias_method :on_csend, :on_send

        private

        def autocorrect(corrector, arg_node)
          return unless arg_node.str_type?

          corrector.replace(arg_node, ":#{arg_node.value}")
        end
      end
    end
  end
end
