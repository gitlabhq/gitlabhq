# frozen_string_literal: true

module RuboCop
  module Cop
    module Database
      # @example
      #   # bad
      #   ActiveRecord::Base.connection
      #
      #   # good
      #   ApplicationRecord.connection
      #
      class MultipleDatabases < RuboCop::Cop::Cop
        AR_BASE_MESSAGE = <<~EOF
          Do not use methods from ActiveRecord::Base, use the ApplicationRecord class instead
          For fixing offenses related to the ActiveRecord::Base.transaction method, see our guidelines:
          https://docs.gitlab.com/ee/development/database/transaction_guidelines.html
        EOF

        def_node_matcher :active_record_base_method_is_used?, <<~PATTERN
        (send (const (const nil? :ActiveRecord) :Base) $_)
        PATTERN

        def on_send(node)
          return unless active_record_base_method_is_used?(node)

          add_offense(node, location: :expression, message: AR_BASE_MESSAGE)
        end
      end
    end
  end
end
