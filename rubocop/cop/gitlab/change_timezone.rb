# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      class ChangeTimezone < RuboCop::Cop::Cop
        MSG = "Do not change timezone in the runtime (application or rspec), " \
          "it could result in silently modifying other behavior."

        def_node_matcher :changing_timezone?, <<~PATTERN
          (send (const nil? :Time) :zone= ...)
        PATTERN

        def on_send(node)
          changing_timezone?(node) { add_offense(node) }
        end
      end
    end
  end
end
