# frozen_string_literal: true

module Gitlab
  module Database
    class CiBuildsPartitioning
      include AsyncDdlExclusiveLeaseGuard

      ATTEMPTS = 10
      LOCK_TIMEOUT = 10.seconds
      LEASE_TIMEOUT = 35.minutes

      def initialize(logger: Gitlab::AppLogger)
        @connection = ::Ci::ApplicationRecord.connection
        @timing_configuration = Array.new(ATTEMPTS) { [LOCK_TIMEOUT, rand((1.minute)..(3.minutes))] }
        @logger = logger
      end

      def execute
        return unless can_execute?

        try_obtain_lease do
          lock_retries.run(raise_on_exhaustion: true) do
            connection.execute(partitioning_sql)
          end

          log_info('Partition attached')
        end

      rescue WithLockRetries::AttemptsExhaustedError
        log_info('Failed to attach partition')
      end

      private

      attr_reader :connection, :timing_configuration, :logger

      def can_execute?
        return false if process_disabled?
        return false unless Gitlab.com?
        return false unless connection.table_exists?(:p_ci_builds)

        if already_attached?
          log_info('Table already attached')

          return false
        end

        if vacuum_running?
          log_info('Autovacuum detected')

          return false
        end

        true
      end

      def process_disabled?
        ::Feature.disabled?(:attach_ci_builds_partition)
      end

      def already_attached?
        Gitlab::Database::SharedModel.using_connection(connection) do
          Gitlab::Database::PostgresPartition
            .for_parent_table('public.p_ci_builds')
            .for_identifier('public.ci_builds')
            .exists?
        end
      end

      def vacuum_running?
        Gitlab::Database::SharedModel.using_connection(connection) do
          Gitlab::Database::PostgresAutovacuumActivity
            .for_tables(%i[ci_pipelines ci_stages ci_builds ci_resource_groups])
            .any?
        end
      end

      def lock_retries
        Gitlab::Database::WithLockRetries.new(
          timing_configuration: timing_configuration,
          connection: connection,
          logger: logger,
          klass: self.class
        )
      end

      def partitioning_sql
        <<~SQL.squish
          SET LOCAL statement_timeout TO '11s';

          LOCK ci_pipelines, ci_stages, ci_builds, ci_resource_groups IN ACCESS EXCLUSIVE MODE;

          DROP TRIGGER IF EXISTS ci_builds_loose_fk_trigger ON ci_builds;

          ALTER TABLE p_ci_builds ATTACH PARTITION ci_builds FOR VALUES IN (100);

          ALTER SEQUENCE ci_builds_id_seq OWNED BY p_ci_builds.id;
          ALTER TABLE p_ci_builds DROP CONSTRAINT partitioning_constraint;

          CREATE TRIGGER ci_builds_loose_fk_trigger
            AFTER DELETE ON ci_builds
            REFERENCING OLD TABLE AS old_table
            FOR EACH STATEMENT EXECUTE FUNCTION insert_into_loose_foreign_keys_deleted_records();

          CREATE TRIGGER p_ci_builds_loose_fk_trigger
            AFTER DELETE ON p_ci_builds
            REFERENCING OLD TABLE AS old_table
            FOR EACH STATEMENT EXECUTE FUNCTION insert_into_loose_foreign_keys_deleted_records();
        SQL
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
