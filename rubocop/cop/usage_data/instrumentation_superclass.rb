# frozen_string_literal: true

module RuboCop
  module Cop
    module UsageData
      # This cop checks that metric instrumentation classes subclass one of the allowed base classes.
      #
      # @example
      #
      #  # good
      #  class CountIssues < DatabaseMetric
      #    # ...
      #  end
      #
      #  # bad
      #  class CountIssues < BaseMetric
      #    # ...
      #  end
      class InstrumentationSuperclass < RuboCop::Cop::Cop
        MSG = "Instrumentation classes should subclass one of the following: %{allowed_classes}."

        BASE_PATTERN = "(const nil? !#allowed_class?)"

        def_node_matcher :class_definition, <<~PATTERN
          (class (const _ !#allowed_class?) #{BASE_PATTERN} ...)
        PATTERN

        def_node_matcher :class_new_definition, <<~PATTERN
          [!^(casgn {nil? cbase} #allowed_class? ...)
           !^^(casgn {nil? cbase} #allowed_class? (block ...))
           (send (const {nil? cbase} :Class) :new #{BASE_PATTERN})]
        PATTERN

        def on_class(node)
          class_definition(node) do
            register_offense(node.children[1])
          end
        end

        def on_send(node)
          class_new_definition(node) do
            register_offense(node.children.last)
          end
        end

        private

        def allowed_class?(class_name)
          allowed_classes.include?(class_name)
        end

        def allowed_classes
          cop_config['AllowedClasses'] || []
        end

        def register_offense(offense_node)
          message = format(MSG, allowed_classes: allowed_classes.join(', '))
          add_offense(offense_node, message: message)
        end
      end
    end
  end
end
