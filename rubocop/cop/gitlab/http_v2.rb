# frozen_string_literal: true

begin
  require 'gitlab-http'
rescue LoadError
  # Ignore the cop if the gem is not available
  return
end

module RuboCop
  module Cop
    module Gitlab
      class HttpV2 < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        METHODS_LIST = ::Gitlab::HTTP_V2::SUPPORTED_HTTP_METHODS.join(', ').freeze
        METHODS_PATTERN = ::Gitlab::HTTP_V2::SUPPORTED_HTTP_METHODS.map(&:inspect).join(' ').freeze

        MSG_SEND = <<~MSG.freeze
          Avoid calling `Gitlab::HTTP_V2` directly for the #{METHODS_LIST} methods.
          Instead, use the `Gitlab::HTTP` wrapper.
        MSG

        def_node_matcher :http_v2_node?, <<~PATTERN
          (send (const (const nil? :Gitlab) :HTTP_V2) {#{METHODS_PATTERN}} ...)
        PATTERN

        def on_send(node)
          return unless http_v2_node?(node)

          add_offense(node, message: MSG_SEND) do |corrector|
            _, method_name, *arg_nodes = *node

            replacement = "Gitlab::HTTP.#{method_name}(#{arg_nodes.map(&:source).join(', ')})"

            corrector.replace(node.source_range, replacement)
          end
        end
      end
    end
  end
end
