# frozen_string_literal: true

module RuboCop
  module Cop
    module Database
      # Disallows the use of scope_to to avoid problematic batched background migration
      # queries.
      #
      # @example
      #
      #   # bad
      #   class CustomBatchedMigrationClass < BatchedMigrationJob
      #     scope_to ->(relation) { relation.where( user_type: "ADMIN") }
      #   end
      #
      #   # good
      #   class CustomBatchedMigrationClass < BatchedMigrationJob
      #     def perform
      #       each_sub_batch do |relation|
      #         relation.where( user_type: "ADMIN").update_all("column = 'foo'")
      #       end
      #     end
      #   end
      class AvoidScopeTo < RuboCop::Cop::Base
        include RangeHelp

        MSG = "Avoid using `scope_to` inside batched background migration class definitions https://docs.gitlab.com/development/database/batched_background_migrations/#use-of-scope_to"

        def on_class(node)
          node.each_descendant(:send) do |send_node|
            next unless send_node.method?(:scope_to)

            add_offense(send_node.loc.selector)
          end
        end
      end
    end
  end
end
