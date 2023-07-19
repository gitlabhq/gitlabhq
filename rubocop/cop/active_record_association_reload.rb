# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that denylists the use of `reload`.
    class ActiveRecordAssociationReload < RuboCop::Cop::Base
      MSG = 'Use reset instead of reload. ' \
        'For more details check the https://gitlab.com/gitlab-org/gitlab-foss/issues/60218.'

      def_node_matcher :reload?, <<~PATTERN
        (send _ :reload ...)
      PATTERN

      def on_send(node)
        return unless reload?(node)

        add_offense(node.loc.selector)
      end
    end
  end
end
