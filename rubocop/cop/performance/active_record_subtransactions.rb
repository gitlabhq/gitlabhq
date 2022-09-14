# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      class ActiveRecordSubtransactions < RuboCop::Cop::Base
        MSG = 'Subtransactions should not be used. ' \
          'For more information see: https://gitlab.com/gitlab-org/gitlab/-/issues/338346'

        def_node_matcher :match_transaction_with_options, <<~PATTERN
          (send _ :transaction (hash $...))
        PATTERN

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
