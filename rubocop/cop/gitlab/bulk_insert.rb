# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop that disallows the use of `Gitlab::Database.main.bulk_insert`, in favour of using
      # the `BulkInsertSafe` module.
      class BulkInsert < RuboCop::Cop::Cop
        MSG = 'Use the `BulkInsertSafe` concern, instead of using `Gitlab::Database.main.bulk_insert`. See https://docs.gitlab.com/ee/development/insert_into_tables_in_batches.html'

        def_node_matcher :raw_union?, <<~PATTERN
          (send (send (const (const _ :Gitlab) :Database) :main) :bulk_insert ...)
        PATTERN

        def on_send(node)
          return unless raw_union?(node)

          add_offense(node, location: :expression)
        end
      end
    end
  end
end
