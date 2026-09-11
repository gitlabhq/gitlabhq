# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class PartitionManager
        include ::Gitlab::Loggable
        include ::Gitlab::Utils::StrongMemoize
        include ::Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

        LEASE_TIMEOUT = 1.hour
        STATEMENT_TIMEOUT = 1.hour
        MANAGEMENT_LEASE_KEY = 'database_partition_management_%s'
        RETAIN_DETACHED_PARTITIONS_FOR = 1.week
        MAX_PARTITION_SIZE = 150.gigabytes
        DETACH_DEFERRAL_GRACE = 2.weeks

        UnableToDetachPartition = Class.new(StandardError)

        def initialize(model, connection: nil)
          @model = model
          @connection = connection || model.connection
          @connection_name = @connection.pool.db_config.name
        end

        def execute(sql)
          @connection.execute(sql)
        end

        def sync_partitions(analyze: true)
          partitions_to_create = []
          partitions_to_detach = []
          @detach_error_messages = []

          return skip_syncing_partitions unless table_partitioned?

          Gitlab::AppLogger.info(log_payload(message: 'Checking state of dynamic postgres partitions'))

          only_with_exclusive_lease(model, lease_key: MANAGEMENT_LEASE_KEY) do
            model.partitioning_strategy.validate_and_fix

            partitions_to_create = missing_partitions
            partitions_to_detach = extra_partitions

            create(partitions_to_create) unless partitions_to_create.empty?
            detach(partitions_to_detach) unless partitions_to_detach.empty?

            run_analyze(partitions_to_create) if analyze

            raise_unable_to_detach_partition if @detach_error_messages.any?
          end
        rescue ArgumentError, UnableToDetachPartition => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        rescue StandardError => e
          Gitlab::AppLogger.error(
            log_payload(
              message: 'Failed to create / detach partition(s)',
              exception_class: e.class,
              exception_message: e.message,
              partitions_to_create: partitions_to_create.map(&:partition_name),
              partitions_to_detach: partitions_to_detach.map(&:partition_name)
            )
          )
        end

        private

        attr_reader :model, :connection

        # Create all partition tables (doesn't take any lock on parent)
        def create_partition_tables(partitions)
          partitions.each do |partition|
            connection.execute(partition.to_create_sql)
          end
        end

        # Attach all partitions (takes SHARE UPDATE EXCLUSIVE lock)
        def attach_partition_tables(partitions)
          partitions.each do |partition|
            connection.execute(partition.to_attach_sql)
            process_created_partition(partition)
          end
        end

        def process_created_partition(partition)
          Gitlab::AppLogger.info(log_payload(message: 'Created partition', partition_name: partition.partition_name))

          lock_partitions_for_writes(partition) if should_lock_for_writes?

          attach_loose_foreign_key_trigger(partition) if parent_table_has_loose_foreign_key?
        end

        def missing_partitions
          return [] unless connection.table_exists?(model.table_name)

          model.partitioning_strategy.missing_partitions
        end

        def extra_partitions
          return [] unless connection.table_exists?(model.table_name)

          model.partitioning_strategy.extra_partitions
        end

        def only_with_exclusive_lease(model, lease_key:)
          lease = Gitlab::ExclusiveLease.new(lease_key % model.table_name, timeout: LEASE_TIMEOUT)

          yield if lease.try_obtain
        ensure
          lease&.cancel
        end

        def create(partitions)
          # with_lock_retries starts a requires_new transaction most of the time, but not on the last iteration
          with_lock_retries do
            connection.transaction(requires_new: false) do # so we open a transaction here if not already in progress
              create_partition_tables(partitions)
              attach_partition_tables(partitions)

              model.partitioning_strategy.after_adding_partitions
            end
          end
        end

        def detach(partitions)
          detachable = partitions.select { |p| detachable?(p) }
          return if detachable.empty?

          # CONCURRENTLY cannot run in a transaction
          return detachable.each { |p| detach_one_partition(p, concurrently: true) } if detach_concurrently?

          # with_lock_retries starts a requires_new transaction most of the time, but not on the last iteration
          with_lock_retries do
            connection.transaction(requires_new: false) do # so we open a transaction here if not already in progress
              detachable.each { |p| detach_one_partition(p) }
            end
          end
        end

        def detach_one_partition(partition, concurrently: false)
          schedule_detached_partition_cleanup(partition)

          connection.execute partition.to_detach_sql(concurrently: concurrently)

          Gitlab::AppLogger.info(log_payload(
            message: 'Detached Partition',
            partition_name: partition.partition_name,
            concurrent: concurrently
          ))
        end

        def detach_concurrently?
          model.partitioning_strategy.detach_concurrently?
        end
        strong_memoize_attr :detach_concurrently?

        def detachable?(partition)
          check = DetachEligibility.new(partition, connection: connection, detach_concurrently: detach_concurrently?)
          return true if check.detachable?

          log_detach_blocker(partition, check.blocker)
          escalate_long_detach_deferral(partition, check.blocker)
          false
        rescue ActiveRecord::StatementInvalid => e
          log_detach_blocker(partition, DetachEligibility::Blocker.new(
            reason: :database_error, level: :error, details: { exception_message: e.message }
          ))
          false
        end

        def log_detach_blocker(partition, blocker)
          payload = log_payload(
            message: blocker.level == :error ? 'Cannot detach partition' : 'Deferred detaching partition',
            blocker_reason: blocker.reason,
            partition_name: partition.partition_name,
            **blocker.details
          )

          case blocker.level
          when :warn
            Gitlab::AppLogger.warn(payload)
          when :error
            Gitlab::AppLogger.error(payload)
            @detach_error_messages << "#{partition.partition_name} (#{blocker.reason})"
          else
            Gitlab::AppLogger.info(payload)
          end
        end

        # If a detach has been deferred for too long, we escalate it to an error.
        def escalate_long_detach_deferral(partition, blocker)
          return if blocker.level == :error

          duration = deferral_duration(partition)
          return unless duration && duration > max_detach_deferral

          Gitlab::AppLogger.error(log_payload(
            message: 'Detach deferred for too long',
            partition_name: partition.partition_name,
            blocker_reason: blocker.reason,
            deferral_duration_s: duration
          ))

          @detach_error_messages << "#{partition.partition_name} (deferred too long)"
        end

        def deferral_duration(partition)
          detachable_since = model.partitioning_strategy.detachable_since(partition)
          return unless detachable_since

          ::Time.current - detachable_since
        end

        # A referencing partition detaches, waits out a retention period of its own, then drops
        # on a later run (it could be delayed until the weekend if it exceeds MAX_PARTITION_SIZE),
        # so DETACH_DEFERRAL_GRACE must account for this timing.
        def max_detach_deferral
          detached_partition_retention_period + DETACH_DEFERRAL_GRACE
        end

        # An :error blocker is a misconfigured table or a database error in the eligibility check, and it must
        # reach error tracking. We raise after the run finishes, so the other partitions still get detached.
        def raise_unable_to_detach_partition
          raise UnableToDetachPartition,
            "Unable to detach partitions of #{model.table_name}: #{@detach_error_messages.join(', ')}"
        end

        def log_payload(**params)
          build_structured_payload_labkit(
            table_name: model.table_name,
            connection_name: @connection_name,
            **params
          )
        end

        def with_lock_retries(&block)
          Gitlab::Database::Partitioning::WithPartitioningLockRetries.new(
            klass: self.class,
            logger: Gitlab::AppLogger,
            connection: connection,
            extra_log_params: { table_name: model.table_name }
          ).run(raise_on_exhaustion: true, &block)
        end

        def table_partitioned?
          Gitlab::Database::SharedModel.using_connection(connection) do
            Gitlab::Database::PostgresPartitionedTable.find_by_name_in_current_schema(model.table_name).present?
          end
        end

        def skip_syncing_partitions
          Gitlab::AppLogger.warn(log_payload(message: 'Skipping syncing partitions'))
        end

        # Rescued separately so an ANALYZE failure is not logged as a partition
        # create/detach failure: by this point those already committed.
        def run_analyze(created_partitions)
          analyzed = with_analyze_error_handling('Failed to run ANALYZE on partitioned table') do
            run_analyze_on_partitioned_table
          end

          # The whole-table ANALYZE recurses into every leaf, so the per-partition
          # pass is only needed when the interval throttle skipped it.
          return if analyzed

          with_analyze_error_handling('Failed to run ANALYZE on created partitions') do
            run_analyze_on_created_partitions(created_partitions)
          end
        end

        def with_analyze_error_handling(message)
          yield
        rescue StandardError => e
          Gitlab::AppLogger.error(
            log_payload(
              message: message,
              exception_class: e.class,
              exception_message: e.message
            )
          )

          false
        end

        def run_analyze_on_partitioned_table
          return false if ineligible_for_analyzing?

          primary_transaction(statement_timeout: STATEMENT_TIMEOUT) do
            # Running ANALYZE on partitioned table will go through itself and its partitions
            connection.execute("ANALYZE (SKIP_LOCKED) #{model.quoted_table_name}")
          end

          true
        end

        # A just-created partition has no planner statistics, which can produce
        # pathological plans (INC-13566), so analyze it despite the interval throttle.
        def run_analyze_on_created_partitions(partitions)
          return if partitions.empty? || analyze_interval.blank?
          # Ops kill-switch so post-rotation ANALYZE can be stopped without a deploy
          return unless Feature.enabled?(:analyze_partitioned_tables_on_rotation, type: :ops)

          primary_transaction(statement_timeout: STATEMENT_TIMEOUT) do
            partitions.each do |partition|
              connection.execute("ANALYZE (SKIP_LOCKED) #{connection.quote_table_name(identifier(partition))}")

              next unless analyze_skipped?(partition)

              # SKIP_LOCKED no-ops on lock conflict, leaving the statless state this guards against
              Gitlab::AppLogger.warn(
                log_payload(message: 'ANALYZE skipped on created partition', partition_name: partition.partition_name)
              )
            end
          end
        end

        # ANALYZE always sets reltuples >= 0; -1 means the table was never analyzed
        def analyze_skipped?(partition)
          connection.select_value(
            "SELECT reltuples FROM pg_class WHERE oid = '#{identifier(partition)}'::regclass"
          ).to_f < 0
        end

        def ineligible_for_analyzing?
          analyze_interval.blank? ||
            first_model_partition.blank? ||
            last_analyzed_at_within_interval?
        end

        def last_analyzed_at_within_interval?
          table_to_query = first_model_partition.identifier

          primary_transaction do
            # We don't need to get the last_analyze_time from partitioned table,
            # because it's not supported and always returns NULL for PG version below 14
            # Therefore, we can always get the last_analyze_time from the first partition
            last_analyzed_at = connection.select_value(
              "SELECT pg_stat_get_last_analyze_time('#{table_to_query}'::regclass)"
            )
            last_analyzed_at.present? && last_analyzed_at >= ::Time.current - analyze_interval
          end
        end

        def first_model_partition
          Gitlab::Database::SharedModel.using_connection(connection) do
            Gitlab::Database::PostgresPartition.for_parent_table(model.table_name).first
          end
        end
        strong_memoize_attr :first_model_partition

        def analyze_interval
          model.partitioning_strategy.analyze_interval
        end

        def primary_transaction(statement_timeout: nil)
          Gitlab::Database::LoadBalancing::SessionMap.current(connection.load_balancer).use_primary do
            connection.transaction(requires_new: false) do
              if statement_timeout.present?
                connection.execute(
                  format("SET LOCAL statement_timeout TO '%ds'", statement_timeout)
                )
              end

              yield
            end
          end
        end

        def should_lock_for_writes?
          Feature.enabled?(:automatic_lock_writes_on_table, type: :ops) &&
            Gitlab::Database.database_mode == Gitlab::Database::MODE_MULTIPLE_DATABASES &&
            connection != model.connection
        end
        strong_memoize_attr :should_lock_for_writes?

        def lock_partitions_for_writes(partition)
          table_name = "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{partition.partition_name}"
          Gitlab::Database::LockWritesManager.new(
            table_name: table_name,
            connection: connection,
            database_name: @connection_name,
            with_retries: !connection.transaction_open?
          ).lock_writes
        end

        def attach_loose_foreign_key_trigger(partition)
          partition_identifier = "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{partition.partition_name}"

          return unless has_loose_foreign_key?(partition.table)

          track_record_deletions_for_partition(partition_identifier, partition.table)
        end

        def parent_table_has_loose_foreign_key?
          has_loose_foreign_key?(model.table_name)
        end
        strong_memoize_attr :parent_table_has_loose_foreign_key?

        def schedule_detached_partition_cleanup(partition)
          identifier = identifier(partition)
          retention = detached_partition_retention_period

          if above_threshold?(identifier)
            Postgresql::DetachedPartition.create!(
              table_name: partition.partition_name,
              drop_after: retention.from_now.next_occurring(:saturday)
            )
          else
            Postgresql::DetachedPartition.create!(
              table_name: partition.partition_name,
              drop_after: retention.from_now
            )
          end
        end

        def detached_partition_retention_period
          model.partitioning_strategy.try(:retain_detached_partitions_for) || RETAIN_DETACHED_PARTITIONS_FOR
        end

        def above_threshold?(identifier)
          Gitlab::Database::SharedModel.using_connection(connection) do
            Gitlab::Database::PostgresPartition
              .for_identifier(identifier)
              .above_threshold(MAX_PARTITION_SIZE)
              .exists?
          end
        end

        def identifier(partition)
          "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{partition.partition_name}"
        end
      end
    end
  end
end
