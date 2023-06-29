# frozen_string_literal: true

module Gitlab
  module Database
    class CiBuildsPartitioning
      include AsyncDdlExclusiveLeaseGuard

      ATTEMPTS = 5
      LOCK_TIMEOUT = 10.seconds
      LEASE_TIMEOUT = 20.minutes

      def initialize(logger: Gitlab::AppLogger)
        @connection = ::Ci::ApplicationRecord.connection
        @timing_configuration = Array.new(ATTEMPTS) { [LOCK_TIMEOUT, 3.minutes] }
        @logger = logger
      end

      def execute
        return unless can_execute?

        try_obtain_lease do
          lock_retries.run(raise_on_exhaustion: true) do
            connection.execute(create_foreign_key_sql)
          end

          log_info('Foreign key successfully created')
        end

      rescue StandardError => e
        log_info("Failed to create foreign key: #{e.message}")
      end

      private

      attr_reader :connection, :timing_configuration, :logger

      def can_execute?
        return false if process_disabled?
        return false unless Gitlab.com?

        if foreign_key_exists?
          log_info('Foreign key exists, nothing to do')

          return false
        end

        if vacuum_running?
          log_info('Autovacuum detected')

          return false
        end

        true
      end

      def process_disabled?
        ::Feature.disabled?(:p_ci_builds_metadata_foreign_key)
      end

      def foreign_key_exists?
        Gitlab::Database::SharedModel.using_connection(connection) do
          Gitlab::Database::PostgresForeignKey
            .by_constrained_table_name_or_identifier(:p_ci_builds_metadata)
            .by_referenced_table_name(:p_ci_builds)
            .by_name(:temp_fk_e20479742e_p)
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

      def lock_retries
        Gitlab::Database::WithLockRetries.new(
          timing_configuration: timing_configuration,
          connection: connection,
          logger: logger,
          klass: self.class
        )
      end

      def create_foreign_key_sql
        <<~SQL.squish
          SET LOCAL statement_timeout TO '11s';

          LOCK TABLE ci_builds, p_ci_builds, p_ci_builds_metadata IN ACCESS EXCLUSIVE MODE;

          ALTER TABLE p_ci_builds_metadata
            ADD CONSTRAINT temp_fk_e20479742e_p
            FOREIGN KEY (partition_id, build_id)
            REFERENCES p_ci_builds (partition_id, id)
            ON UPDATE CASCADE ON DELETE CASCADE;
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
