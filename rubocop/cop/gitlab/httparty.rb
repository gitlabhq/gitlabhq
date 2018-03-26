require_relative '../../spec_helpers'

module RuboCop
  module Cop
    module Gitlab
      class HTTParty < RuboCop::Cop::Cop
        include SpecHelpers

        MSG_SEND = <<~EOL.freeze
          Avoid calling `HTTParty` directly. Instead, use the Gitlab::HTTP
          wrapper. To allow request to localhost or the private network set
          the option :allow_local_requests in the request call.
        EOL

        MSG_INCLUDE = <<~EOL.freeze
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
          return if in_spec?(node)

          add_offense(node, location: :expression, message: MSG_SEND) if httparty_node?(node)
          add_offense(node, location: :expression, message: MSG_INCLUDE) if includes_httparty?(node)
        end

        def autocorrect(node)
          if includes_httparty?(node)
            autocorrect_includes_httparty(node)
          else
            autocorrect_httparty_node(node)
          end
        end

        def autocorrect_includes_httparty(node)
          lambda do |corrector|
            corrector.remove(node.source_range)
          end
        end

        def autocorrect_httparty_node(node)
          _, method_name, *arg_nodes = *node

          replacement = "Gitlab::HTTP.#{method_name}(#{arg_nodes.map(&:source).join(', ')})"

          lambda do |corrector|
            corrector.replace(node.source_range, replacement)
          end
        end
      end
    end
  end
end
