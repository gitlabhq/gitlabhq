# frozen_string_literal: true

module RuboCop
  module Cop
    # Enforces the use of 'class_methods' instead of 'module ClassMethods'
    # For more information see: https://gitlab.com/gitlab-org/gitlab-ce/issues/50414
    #
    # @example
    #   # bad
    #   module Foo
    #     module ClassMethods
    #       def a_class_method
    #       end
    #     end
    #   end
    #
    #   # good
    #   module Foo
    #     class_methods do
    #       def a_class_method
    #       end
    #     end
    #   end
    #
    class PreferClassMethodsOverModule < RuboCop::Cop::Cop
      include RangeHelp

      MSG = 'Do not use module ClassMethods, use class_methods block instead.'

      def on_module(node)
        add_offense(node) if node.defined_module_name == 'ClassMethods'
      end

      def autocorrect(node)
        lambda do |corrector|
          corrector.replace(module_range(node), 'class_methods do')
        end
      end

      private

      def module_range(node)
        module_node, _ = *node
        range_between(node.loc.keyword.begin_pos, module_node.source_range.end_pos)
      end
    end
  end
end
