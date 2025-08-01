# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Cop that disallows certain methods that rely on subtransactions in their implementation.
      # Companion to Performance/ActiveRecordSubtransactions, which bans direct usage of subtransactions.
      # @example
      #
      #   # bad
      #   User.create_or_find_by(name: 'Alice')
      #
      #   # good
      #   User.find_or_create_by(name: 'Alice')
      #
      #   # Disallowed method `safe_find_or_create_by` or `safe_find_or_create_by!`
      #   # bad
      #   User.safe_find_or_create_by!(email: 'alice@example.com')
      #
      #   # good
      #   User.find_or_create_by!(email: 'alice@example.com')
      #
      #   # Disallowed method `with_fast_read_statement_timeout`
      #   # bad
      #   record.with_fast_read_statement_timeout do
      #      record.some_heavy_read_operation
      #   end
      #
      #   # good
      #   record.some_heavy_read_operation
      class ActiveRecordSubtransactionMethods < RuboCop::Cop::Base
        MSG = 'Methods that rely on subtransactions should not be used. ' \
          'For more information see: https://gitlab.com/gitlab-org/gitlab/-/issues/338346'

        DISALLOWED_METHODS = %i[
          safe_ensure_unique
          safe_find_or_create_by
          safe_find_or_create_by!
          with_fast_read_statement_timeout
          create_or_find_by
          create_or_find_by!
        ].to_set.freeze

        def on_send(node)
          return unless DISALLOWED_METHODS.include?(node.method_name)

          add_offense(node.loc.selector)
        end
      end
    end
  end
end
