# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that rejects the usage of `User#admin?`
    class UserAdmin < RuboCop::Cop::Cop
      MSG = 'Direct calls to `User#admin?` to determine admin status should be ' \
        'avoided as they will not take into account the policies framework ' \
        'and will ignore Admin Mode if enabled. Please use a policy check ' \
        'with `User#can_admin_all_resources?` or `User#can_read_all_resources?`.'

      def_node_matcher :admin_call?, <<~PATTERN
        ({send | csend} _ :admin? ...)
      PATTERN

      def on_send(node)
        on_handler(node)
      end

      def on_csend(node)
        on_handler(node)
      end

      private

      def on_handler(node)
        return unless admin_call?(node)

        add_offense(node, location: :selector)
      end
    end
  end
end
