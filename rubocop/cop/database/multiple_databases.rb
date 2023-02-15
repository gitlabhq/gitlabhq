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
      class MultipleDatabases < RuboCop::Cop::Base
        AR_BASE_MESSAGE = <<~EOF
          Do not use methods from ActiveRecord::Base, use the ApplicationRecord class instead
          For fixing offenses related to the ActiveRecord::Base.transaction method, see our guidelines:
          https://docs.gitlab.com/ee/development/database/transaction_guidelines.html
        EOF

        ALLOWED_METHODS = %i[
          no_touching
          configurations
          connection_handler
          logger
        ].freeze

        def_node_matcher :active_record_base_method_is_used?, <<~PATTERN
        (send (const (const _ :ActiveRecord) :Base) $_)
        PATTERN

        def on_send(node)
          return unless active_record_base_method_is_used?(node)

          active_record_base_method = node.children[1]
          return if method_is_allowed?(active_record_base_method)

          add_offense(node, message: AR_BASE_MESSAGE)
        end

        private

        def method_is_allowed?(method_name)
          ALLOWED_METHODS.include?(method_name.to_sym)
        end
      end
    end
  end
end
