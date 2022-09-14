# frozen_string_literal: true

module RuboCop
  module Cop
    module Database
      # Cop that checks if 'disable_referential_integrity' method is called.
      class DisableReferentialIntegrity < RuboCop::Cop::Base
        MSG = <<~TEXT
        Do not use `disable_referential_integrity`, disable triggers in a safe
        transaction instead. Follow the format:
          BEGIN;
          ALTER TABLE my_table DISABLE TRIGGER ALL;
          -- execute query that requires disabled triggers
          ALTER TABLE my_table ENABLE TRIGGER ALL;
          COMMIT;
        TEXT

        def_node_matcher :disable_referential_integrity?, <<~PATTERN
          (send _ :disable_referential_integrity)
        PATTERN

        RESTRICT_ON_SEND = %i[disable_referential_integrity].freeze

        def on_send(node)
          return unless disable_referential_integrity?(node)

          add_offense(node)
        end
      end
    end
  end
end
