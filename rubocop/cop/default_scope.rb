# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that denylists the use of `default_scope`.
    class DefaultScope < RuboCop::Cop::Base
      MSG = <<~EOF
        Do not use `default_scope`, as it does not follow the principle of
        least surprise. See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/33847
        for more details.
      EOF

      def_node_matcher :default_scope?, <<~PATTERN
        (send {nil? (const nil? ...)} :default_scope ...)
      PATTERN

      def on_send(node)
        return unless default_scope?(node)

        add_offense(node)
      end
    end
  end
end
