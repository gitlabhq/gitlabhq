# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      # Decides if we can safely detach a partition.
      #
      # Two conditions concern the partition itself, and failing either makes Postgres refuse outright:
      #
      #   1. for a concurrent detach, the parent has no DEFAULT partition
      #   2. the partition is not awaiting FINALIZE from an interrupted concurrent detach
      #
      # If any table holds a foreign key to the partition's parent, Postgres detaches the partition
      # only after proving no row still references it. To prove that, it queries every table with a
      # foreign key to the parent. The query prunes to nothing only when all of these hold:
      #
      #   3. no referencing table has a DEFAULT partition, which holds no partition id bound
      #   4. no detached partition of a referencing table still carries a foreign key to the parent
      #   5. every referencing table is list partitioned on the key the parent is partitioned on
      #   6. every referencing table has already dropped its partition for the same partition ids
      #
      # The detach errors when it fails condition #6. Failing one of the other referencing
      # conditions makes it read a whole referencing table, inside the DETACH statement and
      # under a lock on its parent. Only partitions that can successfully detach without paying
      # the full scan cost are eligible for detach. See cost measured per shape analysis:
      # https://gitlab.com/gitlab-org/gitlab/-/work_items/552078#note_3689127853
      #
      # Currently, this class only supports tables that are list partitioned on a single integer
      # column. The partition being detached must also live in the dynamic partitions schema.
      class DetachEligibility
        include ::Gitlab::Utils::StrongMemoize

        Blocker = Struct.new(:reason, :level, :details, keyword_init: true)

        LIST_STRATEGY = 'list'

        attr_reader :blocker

        def initialize(partition, connection:, detach_concurrently: false)
          @partition = partition
          @connection = connection
          @detach_concurrently = detach_concurrently
          @blocker = nil
        end

        def detachable?
          with_connection do
            next false unless supported_detach? && not_pending_detach?
            next true if referencing_foreign_keys.empty?

            referencing_conditions_satisfied?
          end
        end
        strong_memoize_attr :detachable?

        private

        attr_reader :partition, :connection, :detach_concurrently

        def referencing_conditions_satisfied?
          supported_partition_key? &&
            supported_partition_ids? &&
            no_default_referencing_partition? &&
            no_detached_referencing_partition? &&
            referencing_tables_share_partition_key? &&
            counterpart_partitions_dropped?
        end

        # Postgres refuses DETACH ... CONCURRENTLY while the parent
        # has a DEFAULT partition, but plain DETACH is unaffected.
        def supported_detach?
          return true unless detach_concurrently
          return true unless has_default_partition?(partition.table)

          blocked_by(:parent_has_default_partition, :error)
        end

        # Either form of DETACH errors on a partition awaiting FINALIZE.
        # DetachedPartitionDropper finalizes it once retention elapses.
        def not_pending_detach?
          return true unless pg_partition&.pending_detach

          blocked_by(:partition_pending_detach, :info)
        end

        def supported_partition_key?
          return true if parent_partition_key

          blocked_by(:unsupported_partition_key, :warn)
        end

        def supported_partition_ids?
          return true if partition_ids.any?

          blocked_by(:unsupported_partition_ids, :warn)
        end

        def no_default_referencing_partition?
          foreign_key = referencing_foreign_keys.find { |fk| has_default_partition?(fk.constrained_table_name) }
          return true unless foreign_key

          blocked_by(:referencing_table_has_default_partition, :warn,
            referencing_table: foreign_key.constrained_table_identifier)
        end

        def no_detached_referencing_partition?
          foreign_key = referencing_foreign_keys.find { |fk| on_detached_partition?(fk) }
          return true unless foreign_key

          blocked_by(:detached_referencing_partition, :info,
            referencing_table: foreign_key.constrained_table_identifier)
        end

        def referencing_tables_share_partition_key?
          foreign_key = referencing_foreign_keys.find { |fk| !shares_partition_key?(fk) }
          return true unless foreign_key

          blocked_by(:referencing_table_cannot_prune, :warn,
            referencing_table: foreign_key.constrained_table_identifier,
            foreign_key_name: foreign_key.name)
        end

        def counterpart_partitions_dropped?
          referencing_foreign_keys.each do |foreign_key|
            partition_ids.each do |partition_id|
              next unless counterpart_partition_present?(foreign_key, partition_id)

              return blocked_by(:counterpart_partition_present, :info,
                referencing_table: foreign_key.constrained_table_identifier,
                partition_id: partition_id)
            end
          end

          true
        end

        # The foreign key must map the referencing table's partition key onto the parent's.
        # `postgres_foreign_keys` orders `constrained_columns` and `referenced_columns` by the
        # constraint's own column order, so the two align position by position.
        def shares_partition_key?(foreign_key)
          referencing_partition_key = list_partition_key_for(foreign_key.constrained_table_name)
          return false unless referencing_partition_key

          partition_key_index = foreign_key.referenced_columns.index(parent_partition_key)
          return false unless partition_key_index

          foreign_key.constrained_columns[partition_key_index] == referencing_partition_key
        end

        def counterpart_partition_present?(foreign_key, partition_id)
          PostgresPartition
            .for_parent_table(foreign_key.constrained_table_name)
            .with_list_constraint(partition_id)
            .exists?
        end

        def has_default_partition?(table_name)
          PostgresPartition.for_parent_table(table_name).default_partition.exists?
        end

        # An attached partition can own a non-inherited FK too, so we must
        # also check `postgres_partitions`, which lists only attached ones.
        def on_detached_partition?(non_inherited_foreign_key)
          identifier = non_inherited_foreign_key.constrained_table_identifier

          identifier.start_with?("#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.") &&
            !PostgresPartition.for_identifier(identifier).exists?
        end

        # Inherited FKs are the copies on the referencing table's partitions, so `.not_inherited` gives the
        # one on the table itself. Detaching makes a copy standalone, so a detached partition's FK is here too.
        def referencing_foreign_keys
          PostgresForeignKey.by_referenced_table_identifier(parent_identifier).not_inherited.to_a
        end
        strong_memoize_attr :referencing_foreign_keys

        def pg_partition
          PostgresPartition
            .for_identifier(partition_identifier)
            .find_by(parent_identifier: parent_identifier)
        end
        strong_memoize_attr :pg_partition

        def partition_ids
          pg_partition&.list_partition_ids || []
        end
        strong_memoize_attr :partition_ids

        def parent_partition_key
          list_partition_key_for(partition.table)
        end
        strong_memoize_attr :parent_partition_key

        # Postgres allows the list strategy only one key column, so `first` is the whole key
        def list_partition_key_for(table_name)
          table = PostgresPartitionedTable.find_by_name_in_current_schema(table_name)
          return unless table&.strategy == LIST_STRATEGY

          table.key_columns.first
        end

        def parent_identifier
          "#{connection.current_schema}.#{partition.table}"
        end

        def partition_identifier
          "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{partition.partition_name}"
        end

        # Records why the detach cannot go ahead; returns `false` for the check that found it.
        def blocked_by(reason, level, **details)
          @blocker = Blocker.new(reason: reason, level: level, details: details)

          false
        end

        def with_connection(&block)
          Gitlab::Database::SharedModel.using_connection(connection, &block)
        end
      end
    end
  end
end
