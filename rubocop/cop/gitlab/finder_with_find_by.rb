# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      class FinderWithFindBy < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        FIND_PATTERN = /\Afind(_by!?)?\z/
        ALLOWED_MODULES = ['FinderMethods'].freeze

        def message(used_method)
          <<~MSG
          Don't chain finders `#execute` method with `##{used_method}`.
          Instead include `FinderMethods` in the Finder and call `##{used_method}`
          directly on the finder instance.

          This will make sure all authorization checks are performed on the resource.
          MSG
        end

        def on_send(node)
          return unless find_on_execute?(node) && !allowed_module?(node)

          add_offense(node.loc.selector, message: message(node.method_name)) do |corrector|
            upto_including_execute = node.descendants.first.source_range
            before_execute = node.descendants[1].source_range
            range_to_remove = node.source_range
                                .with(begin_pos: before_execute.end_pos,
                                  end_pos: upto_including_execute.end_pos)

            corrector.remove(range_to_remove)
          end
        end

        def find_on_execute?(node)
          chained_on_node = node.descendants.first
          node.method_name.to_s =~ FIND_PATTERN &&
            chained_on_node.is_a?(RuboCop::AST::SendNode) && chained_on_node.method_name == :execute
        end

        def allowed_module?(node)
          ALLOWED_MODULES.include?(node.parent_module_name)
        end

        def method_name_for_node(node)
          children[1].to_s
        end
      end
    end
  end
end
