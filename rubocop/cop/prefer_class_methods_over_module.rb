# frozen_string_literal: true

module RuboCop
  module Cop
    # Enforces the use of 'class_methods' instead of 'module ClassMethods' for activesupport concerns.
    # For more information see: https://gitlab.com/gitlab-org/gitlab-foss/issues/50414
    #
    # @example
    #   # bad
    #   module Foo
    #     extend ActiveSupport::Concern
    #
    #     module ClassMethods
    #       def a_class_method
    #       end
    #     end
    #   end
    #
    #   # good
    #   module Foo
    #     extend ActiveSupport::Concern
    #
    #     class_methods do
    #       def a_class_method
    #       end
    #     end
    #   end
    #
    class PreferClassMethodsOverModule < RuboCop::Cop::Base
      extend RuboCop::Cop::AutoCorrector
      include RangeHelp

      MSG = 'Do not use module ClassMethods, use class_methods block instead.'

      def_node_matcher :extend_activesupport_concern?, <<~PATTERN
        (:send nil? :extend (:const (:const nil? :ActiveSupport) :Concern))
      PATTERN

      def on_module(node)
        return unless class_methods_module_in_activesupport_concern?(node)

        add_offense(node) do |corrector|
          corrector.replace(module_range(node), 'class_methods do')
        end
      end

      private

      def class_methods_module_in_activesupport_concern?(node)
        node.defined_module_name == 'ClassMethods' &&
          module_extends_activesupport_concern?(node)
      end

      def module_extends_activesupport_concern?(node)
        container_module = container_module_of(node)
        return false unless container_module

        container_module.descendants.any? do |descendant|
          extend_activesupport_concern?(descendant)
        end
      end

      def container_module_of(node)
        while node = node.parent
          break if node.type == :module
        end

        node
      end

      def module_range(node)
        module_node, _ = *node
        range_between(node.loc.keyword.begin_pos, module_node.source_range.end_pos)
      end
    end
  end
end
