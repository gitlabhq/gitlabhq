# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      class Json < RuboCop::Cop::Cop
        MSG = <<~EOL
          Avoid calling `JSON` directly. Instead, use the `Gitlab::Json`
          wrapper. This allows us to alter the JSON parser being used.
        EOL

        def_node_matcher :json_node?, <<~PATTERN
          (send (const {nil? | (const nil? :ActiveSupport)} :JSON)...)
        PATTERN

        def on_send(node)
          add_offense(node) if json_node?(node)
        end

        def autocorrect(node)
          autocorrect_json_node(node)
        end

        def autocorrect_json_node(node)
          _, method_name, *arg_nodes = *node

          replacement = "Gitlab::Json.#{method_name}(#{arg_nodes.map(&:source).join(', ')})"

          lambda do |corrector|
            corrector.replace(node.source_range, replacement)
          end
        end
      end
    end
  end
end
