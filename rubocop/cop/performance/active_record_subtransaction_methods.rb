# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Cop that disallows certain methods that rely on subtransactions in their implementation.
      # Companion to Performance/ActiveRecordSubtransactions, which bans direct usage of subtransactions.
      class ActiveRecordSubtransactionMethods < RuboCop::Cop::Cop
        MSG = 'Methods that rely on subtransactions should not be used. ' \
          'For more information see: https://gitlab.com/gitlab-org/gitlab/-/issues/338346'

        DISALLOWED_METHODS = %i[
          safe_ensure_unique
          create_or_find_by
          create_or_find_by!
        ].freeze

        def on_send(node)
          return unless DISALLOWED_METHODS.include?(node.method_name)

          add_offense(node, location: :selector)
        end
      end
    end
  end
end
