# frozen_string_literal: true

module Gitlab
  module Database
    class CiBuildsPartitioning
      include AsyncDdlExclusiveLeaseGuard

      ATTEMPTS = 5
      LOCK_TIMEOUT = 10.seconds
      LEASE_TIMEOUT = 30.minutes

      FK_NAME = :fk_e20479742e_p
      TEMP_FK_NAME = :temp_fk_e20479742e_p
      NEXT_PARTITION_ID = 101
      BUILDS_PARTITION_NAME = 'gitlab_partitions_dynamic.ci_builds_101'
      ANNOTATION_PARTITION_NAME = 'gitlab_partitions_dynamic.ci_job_annotations_101'
      RUNNER_MACHINE_PARTITION_NAME = 'gitlab_partitions_dynamic.ci_runner_machine_builds_101'

      def initialize(logger: Gitlab::AppLogger)
        @connection = ::Ci::ApplicationRecord.connection
        @timing_configuration = Array.new(ATTEMPTS) { [LOCK_TIMEOUT, 3.minutes] }
        @logger = logger
      end

      def execute
        return unless can_execute?

        try_obtain_lease do
          swap_foreign_keys
          create_new_ci_builds_partition
          create_new_job_annotations_partition
          create_new_runner_machine_partition
        end

      rescue StandardError => e
        log_info("Failed to execute: #{e.message}")
      end

      private

      attr_reader :connection, :timing_configuration, :logger

      delegate :quote_table_name, :quote_column_name, to: :connection

      def swap_foreign_keys
        if new_foreign_key_exists?
          log_info('Foreign key already renamed, nothing to do')

          return
        end

        with_lock_retries do
          connection.execute drop_old_foreign_key_sql

          rename_constraint :p_ci_builds_metadata, TEMP_FK_NAME, FK_NAME

          each_partition do |partition|
            rename_constraint partition.identifier, TEMP_FK_NAME, FK_NAME
          end
        end

        log_info('Foreign key successfully renamed')
      end

      def create_new_ci_builds_partition
        if connection.table_exists?(BUILDS_PARTITION_NAME)
          log_info('p_ci_builds partition exists, nothing to do')
          return
        end

        with_lock_retries do
          connection.execute new_ci_builds_partition_sql
        end

        log_info('Partition for p_ci_builds successfully created')
      end

      def create_new_job_annotations_partition
        if connection.table_exists?(ANNOTATION_PARTITION_NAME)
          log_info('p_ci_job_annotations partition exists, nothing to do')
          return
        end

        with_lock_retries do
          connection.execute new_job_annotations_partition_sql
        end

        log_info('Partition for p_ci_job_annotations successfully created')
      end

      def create_new_runner_machine_partition
        if connection.table_exists?(RUNNER_MACHINE_PARTITION_NAME)
          log_info('p_ci_runner_machine_builds partition exists, nothing to do')
          return
        end

        with_lock_retries do
          connection.execute new_runner_machine_partition_sql
        end

        log_info('Partition for p_ci_runner_machine_builds successfully created')
      end

      def can_execute?
        return false if process_disabled?
        return false unless Gitlab.com?

        if vacuum_running?
          log_info('Autovacuum detected')

          return false
        end

        true
      end

      def process_disabled?
        ::Feature.disabled?(:complete_p_ci_builds_partitioning)
      end

      def new_foreign_key_exists?
        Gitlab::Database::SharedModel.using_connection(connection) do
          Gitlab::Database::PostgresForeignKey
            .by_constrained_table_name_or_identifier(:p_ci_builds_metadata)
            .by_referenced_table_name(:p_ci_builds)
            .by_name(FK_NAME)
            .exists?
        end
      end

      def vacuum_running?
        Gitlab::Database::SharedModel.using_connection(connection) do
          Gitlab::Database::PostgresAutovacuumActivity
            .wraparound_prevention
            .for_tables(%i[ci_builds ci_builds_metadata])
            .any?
        end
      end

      def drop_old_foreign_key_sql
        <<~SQL.squish
          SET LOCAL statement_timeout TO '11s';

          LOCK TABLE ci_builds, p_ci_builds_metadata IN ACCESS EXCLUSIVE MODE;

          ALTER TABLE p_ci_builds_metadata DROP CONSTRAINT #{FK_NAME};
        SQL
      end

      def rename_constraint(table_name, old_name, new_name)
        connection.execute <<~SQL
          ALTER TABLE #{quote_table_name(table_name)}
          RENAME CONSTRAINT #{quote_column_name(old_name)} TO #{quote_column_name(new_name)}
        SQL
      end

      def new_ci_builds_partition_sql
        <<~SQL
          SET LOCAL statement_timeout TO '11s';

          LOCK ci_pipelines, ci_stages IN SHARE ROW EXCLUSIVE MODE;
          LOCK TABLE ONLY p_ci_builds IN ACCESS EXCLUSIVE MODE;

          CREATE TABLE IF NOT EXISTS #{BUILDS_PARTITION_NAME}
            PARTITION OF p_ci_builds
            FOR VALUES IN (#{NEXT_PARTITION_ID});
        SQL
      end

      def new_job_annotations_partition_sql
        <<~SQL
          SET LOCAL statement_timeout TO '11s';

          LOCK TABLE p_ci_builds IN SHARE ROW EXCLUSIVE MODE;
          LOCK TABLE ONLY p_ci_job_annotations IN ACCESS EXCLUSIVE MODE;

          CREATE TABLE IF NOT EXISTS #{ANNOTATION_PARTITION_NAME}
            PARTITION OF p_ci_job_annotations
            FOR VALUES IN (#{NEXT_PARTITION_ID});
        SQL
      end

      def new_runner_machine_partition_sql
        <<~SQL
          SET LOCAL statement_timeout TO '11s';

          LOCK TABLE p_ci_builds IN SHARE ROW EXCLUSIVE MODE;
          LOCK TABLE ONLY p_ci_runner_machine_builds IN ACCESS EXCLUSIVE MODE;

          CREATE TABLE IF NOT EXISTS #{RUNNER_MACHINE_PARTITION_NAME}
            PARTITION OF p_ci_runner_machine_builds
            FOR VALUES IN (#{NEXT_PARTITION_ID});
        SQL
      end

      def with_lock_retries(&block)
        Gitlab::Database::WithLockRetries.new(
          timing_configuration: timing_configuration,
          connection: connection,
          logger: logger,
          klass: self.class
        ).run(raise_on_exhaustion: true, &block)
      end

      def each_partition(&block)
        Gitlab::Database::SharedModel.using_connection(connection) do
          Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_builds_metadata, &block)
        end
      end

      def log_info(message)
        logger.info(message: message, class: self.class.to_s)
      end

      def connection_db_config
        ::Ci::ApplicationRecord.connection_db_config
      end

      def lease_timeout
        LEASE_TIMEOUT
      end
    end
  end
end
