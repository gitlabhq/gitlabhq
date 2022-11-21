# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop that disallows functions that contain only a call to `strong_memoize()`, in favor
      # of `strong_memoize_attr()`.
      class StrongMemoizeAttr < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG = 'Use `strong_memoize_attr`, instead of using `strong_memoize` directly'

        def_node_matcher :strong_memoize?, <<~PATTERN
          (def $_ _
            (block
              $(send nil? :strong_memoize
                (sym $_)
              )
              (args)
              $_
            )
          )
        PATTERN

        def on_def(node)
          method_name, send_node, attr_name, body = strong_memoize?(node)
          return unless method_name

          add_offense(send_node) do |corrector|
            attr_suffix = ", :#{attr_name}" if attr_name != method_name

            corrector.insert_after(node, "\n#{indent(node)}strong_memoize_attr :#{method_name}#{attr_suffix}")
            corrector.replace(node.body, body.source)
          end
        end
      end
    end
  end
end
