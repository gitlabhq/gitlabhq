# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Cop that bans direct usage of subtransactions in active record.
      # @example
      #   # bad
      #   ActiveRecord::Base.transaction(requires_new: true) do
      #     user.update!(active: true)
      #   end
      #
      #   # good
      #   ActiveRecord::Base.transaction do
      #      user.update!(active: true)
      #   end
      class ActiveRecordSubtransactions < RuboCop::Cop::Base
        MSG = 'Subtransactions should not be used. ' \
          'For more information see: https://gitlab.com/gitlab-org/gitlab/-/issues/338346'

        # @!method match_transaction_with_options(node)
        def_node_matcher :match_transaction_with_options, <<~PATTERN
          (send _ :transaction (hash $...))
        PATTERN

        # @!method subtransaction_option?(node)
        def_node_matcher :subtransaction_option?, <<~PATTERN
          (pair (:sym :requires_new) (true))
        PATTERN

        def on_send(node)
          match_transaction_with_options(node) do |option_nodes|
            option_nodes.each do |option_node|
              next unless subtransaction_option?(option_node)

              add_offense(option_node)
            end
          end
        end
      end
    end
  end
end
