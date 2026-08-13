# frozen_string_literal: true

module Gitlab
  module Database
    # Drops the temporary foreign key left behind by the deployments bigint
    # conversion. Dropping it needs ACCESS EXCLUSIVE on both projects and
    # deployments, which post-deployment migrations could not acquire under
    # weekday load. Reindexing runs during the weekend maintenance window, so it
    # can afford to wait for the lock.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/609534
    class DropTmpDeploymentsProjectIdFk
      include AsyncDdlExclusiveLeaseGuard

      FK_NAME = :fk_b9a3851b82_tmp
      CONSTRAINED_TABLE = :deployments
      REFERENCED_TABLE = :projects
      LEASE_TIMEOUT = 30.minutes

      # Copied from RemoveTmpBigintFkForDeploymentsPhaseTwoRetryTwo. The default
      # timings top out at a 2 second lock_timeout, which was not enough.
      TIMING_CONFIGURATION = ([
        [1.second, 1.minute],
        [2.seconds, 1.minute],
        [3.seconds, 1.minute],
        [5.seconds, 1.minute],
        [7.seconds, 1.minute]
      ] * 3).freeze

      def initialize(logger: Gitlab::AppLogger)
        @logger = logger
      end

      def execute
        return unless can_execute?

        try_obtain_lease do
          with_lock_retries { execute_ddl }
          log_info('Foreign key successfully dropped')
        end
      rescue StandardError => e
        # Never fail the surrounding reindexing task; the next window retries.
        log_info("Failed to execute: #{e.message}")
      end

      def connection
        ::ApplicationRecord.connection
      end

      def connection_db_config
        ::ApplicationRecord.connection_db_config
      end

      def lease_timeout
        LEASE_TIMEOUT
      end

      private

      attr_reader :logger

      def can_execute?
        return false if process_disabled?
        return false unless foreign_key_exists?
        return true unless wraparound_vacuum_running?

        log_info('Autovacuum detected')

        false
      end

      def process_disabled?
        ::Feature.disabled?(:drop_tmp_deployments_project_id_fk, :instance, type: :ops)
      end

      def foreign_key_exists?
        with_shared_connection do
          Gitlab::Database::PostgresForeignKey
            .by_constrained_table_name(CONSTRAINED_TABLE)
            .by_referenced_table_name(REFERENCED_TABLE)
            .by_name(FK_NAME)
            .exists?
        end
      end

      def wraparound_vacuum_running?
        with_shared_connection do
          Gitlab::Database::PostgresAutovacuumActivity
            .wraparound_prevention
            .for_tables([CONSTRAINED_TABLE, REFERENCED_TABLE])
            .any?
        end
      end

      def execute_ddl
        connection.execute(drop_foreign_key_sql) # rubocop:disable Database/AvoidUsingConnectionExecute -- DDL must run on the primary
      end

      # Lock order matches the reverse_lock_order: true the migration used.
      def drop_foreign_key_sql
        <<~SQL.squish
          SET LOCAL statement_timeout TO '11s';

          LOCK TABLE #{REFERENCED_TABLE}, #{CONSTRAINED_TABLE} IN ACCESS EXCLUSIVE MODE;

          ALTER TABLE #{CONSTRAINED_TABLE} DROP CONSTRAINT #{FK_NAME};
        SQL
      end

      def with_lock_retries(&block)
        Gitlab::Database::WithLockRetries.new(
          timing_configuration: TIMING_CONFIGURATION,
          connection: connection,
          logger: logger,
          klass: self.class
        ).run(raise_on_exhaustion: true, &block)
      end

      def with_shared_connection(&block)
        Gitlab::Database::SharedModel.using_connection(connection, &block)
      end

      def log_info(message)
        logger.info(message: message, Labkit::Fields::CLASS_NAME => self.class.to_s)
      end
    end
  end
end
