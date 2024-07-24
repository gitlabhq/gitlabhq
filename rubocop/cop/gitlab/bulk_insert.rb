# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop that disallows the use of `legacy_bulk_insert`, in favour of using
      # the `BulkInsertSafe` module.
      class BulkInsert < RuboCop::Cop::Base
        MSG = 'Use the `BulkInsertSafe` concern, instead of using `LegacyBulkInsert.bulk_insert`. See https://docs.gitlab.com/ee/development/database/insert_into_tables_in_batches.html'

        def_node_matcher :raw_union?, <<~PATTERN
          (send _ :legacy_bulk_insert ...)
        PATTERN

        def on_send(node)
          return unless raw_union?(node)

          add_offense(node)
        end
      end
    end
  end
end
