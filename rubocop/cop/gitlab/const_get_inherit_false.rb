# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop that encourages usage of inherit=false for 2nd argument when using const_get.
      #
      # See https://gitlab.com/gitlab-org/gitlab/issues/27678
      class ConstGetInheritFalse < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG = 'Use inherit=false when using const_get.'

        def_node_matcher :const_get?, <<~PATTERN
        (send _ :const_get ...)
        PATTERN

        def on_send(node)
          return unless const_get?(node)
          return if second_argument(node)&.false_type?

          add_offense(node.loc.selector) do |corrector|
            if arg = second_argument(node)
              corrector.replace(arg.source_range, 'false')
            else
              first_argument = node.arguments[0]
              corrector.insert_after(first_argument.source_range, ', false')
            end
          end
        end

        private

        def second_argument(node)
          node.arguments[1]
        end
      end
    end
  end
end
