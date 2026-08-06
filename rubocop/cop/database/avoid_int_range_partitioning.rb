# frozen_string_literal: true

module RuboCop
  module Cop
    module Database
      # Prevents new usages of the `:int_range` partitioning strategy.
      #
      # `int_range` partition boundaries are derived from the ID sequence of the
      # partitioning key, and sequence ranges are allocated per cell. A destination
      # cell therefore cannot reproduce the partition topology of the source cell,
      # which blocks moving an organization between cells.
      #
      # Use a date-range strategy (`:daily`, `:weekly`, `:monthly`) instead, or reach
      # out to `@gitlab-org/database-team/triage` if that does not fit the access
      # pattern.
      #
      # @example
      #
      #   # bad
      #   partitioned_by :project_id, strategy: :int_range, partition_size: 2_000_000
      #
      #   # bad
      #   partition_table_by_int_range(
      #     'merge_request_diff_commits',
      #     'merge_request_diff_id',
      #     partition_size: 10_000_000,
      #     primary_key: %w[merge_request_diff_id relative_order]
      #   )
      #
      #   # good
      #   partitioned_by :created_at, strategy: :monthly, retain_for: 3.months
      #
      class AvoidIntRangePartitioning < RuboCop::Cop::Base
        MSG = <<~MSG
          Avoid the `:int_range` partitioning strategy.

          Its partition boundaries are derived from ID sequence ranges, which are allocated
          per cell, so a destination cell cannot reproduce the partition topology of the
          source cell. That blocks moving an organization between cells.

          Use a date-range strategy (`:daily`, `:weekly`, `:monthly`) instead, or reach out
          to `@gitlab-org/database-team/triage`.

          See https://docs.gitlab.com/development/database/partitioning/int_range/.
        MSG

        MIGRATION_HELPERS = %i[partition_table_by_int_range create_int_range_partitions].freeze

        RESTRICT_ON_SEND = MIGRATION_HELPERS

        # @!method int_range_strategy?(node)
        def_node_matcher :int_range_strategy?, <<~PATTERN
          (pair (sym :strategy) (sym :int_range))
        PATTERN

        # @!method int_range_migration_helper?(node)
        def_node_matcher :int_range_migration_helper?, <<~PATTERN
          (call {nil? _} {#{MIGRATION_HELPERS.map(&:inspect).join(' ')}} ...)
        PATTERN

        # Matches `partitioned_by :id, strategy: :int_range` as well as the strategy
        # declared for tables registered in config/initializers/postgres_partitioning.rb.
        def on_pair(node)
          add_offense(node) if int_range_strategy?(node)
        end

        def on_send(node)
          add_offense(node.loc.selector) if int_range_migration_helper?(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
