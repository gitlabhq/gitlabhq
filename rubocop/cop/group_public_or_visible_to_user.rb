# frozen_string_literal: true
#
module RuboCop
  module Cop
    # Cop that denylists the usage of Group.public_or_visible_to_user
    class GroupPublicOrVisibleToUser < RuboCop::Cop::Base
      MSG = '`Group.public_or_visible_to_user` should be used with extreme care. ' \
        'Please ensure that you are not using it on its own and that the amount ' \
        'of rows being filtered is reasonable.'

      def_node_matcher :public_or_visible_to_user?, <<~PATTERN
        (send (const nil? :Group) :public_or_visible_to_user ...)
      PATTERN

      def on_send(node)
        return unless public_or_visible_to_user?(node)

        add_offense(node)
      end
    end
  end
end
