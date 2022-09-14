# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      class HTTParty < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG_SEND = <<~EOL
          Avoid calling `HTTParty` directly. Instead, use the Gitlab::HTTP
          wrapper. To allow request to localhost or the private network set
          the option :allow_local_requests in the request call.
        EOL

        MSG_INCLUDE = <<~EOL
          Avoid including `HTTParty` directly. Instead, use the Gitlab::HTTP
          wrapper. To allow request to localhost or the private network set
          the option :allow_local_requests in the request call.
        EOL

        def_node_matcher :includes_httparty?, <<~PATTERN
          (send nil? :include (const nil? :HTTParty))
        PATTERN

        def_node_matcher :httparty_node?, <<~PATTERN
          (send (const nil? :HTTParty)...)
        PATTERN

        def on_send(node)
          if httparty_node?(node)
            add_offense(node, message: MSG_SEND) do |corrector|
              _, method_name, *arg_nodes = *node

              replacement = "Gitlab::HTTP.#{method_name}(#{arg_nodes.map(&:source).join(', ')})"

              corrector.replace(node.source_range, replacement)
            end
          elsif includes_httparty?(node)
            add_offense(node, message: MSG_INCLUDE) do |corrector|
              corrector.remove(node.source_range)
            end
          end
        end
      end
    end
  end
end
