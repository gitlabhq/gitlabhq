# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      # This is a >= PG12 reindexing strategy based on `REINDEX CONCURRENTLY`
      class ReindexConcurrently
        ReindexError = Class.new(StandardError)

        TEMPORARY_INDEX_PATTERN = '\_ccnew[0-9]*'
        STATEMENT_TIMEOUT = 9.hours
        PG_MAX_INDEX_NAME_LENGTH = 63

        # When dropping an index, we acquire a SHARE UPDATE EXCLUSIVE lock,
        # which only conflicts with DDL and vacuum. We therefore execute this with a rather
        # high lock timeout and a long pause in between retries. This is an alternative to
        # setting a high statement timeout, which would lead to a long running query with effects
        # on e.g. vacuum.
        REMOVE_INDEX_RETRY_CONFIG = [[1.minute, 9.minutes]] * 30

        attr_reader :index, :logger

        def initialize(index, logger: Gitlab::AppLogger)
          @index = index
          @logger = logger
        end

        def perform
          raise ReindexError, 'indexes serving an exclusion constraint are currently not supported' if index.exclusion?
          raise ReindexError, 'index is a left-over temporary index from a previous reindexing run' if index.name =~ /#{TEMPORARY_INDEX_PATTERN}/

          # Expression indexes require additional statistics in `pg_statistic`:
          # select * from pg_statistic where starelid = (select oid from pg_class where relname = 'some_index');
          #
          # In PG12, this has been fixed in https://gitlab.com/postgres/postgres/-/commit/b17ff07aa3eb142d2cde2ea00e4a4e8f63686f96.
          # Discussion happened in https://www.postgresql.org/message-id/flat/CAFcNs%2BqpFPmiHd1oTXvcPdvAHicJDA9qBUSujgAhUMJyUMb%2BSA%40mail.gmail.com
          # following a GitLab.com incident that surfaced this (https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2885).
          #
          # While this has been backpatched, we continue to disable expression indexes until further review.
          raise ReindexError, 'expression indexes are currently not supported' if index.expression?

          begin
            with_logging do
              set_statement_timeout do
                execute("REINDEX INDEX CONCURRENTLY #{quote_table_name(index.schema)}.#{quote_table_name(index.name)}")
              end
            end
          ensure
            cleanup_dangling_indexes
          end
        end

        private

        def with_logging
          bloat_size = index.bloat_size
          ondisk_size_before = index.ondisk_size_bytes

          logger.info(
            message: "Starting reindex of #{index}",
            index: index.identifier,
            table: index.tablename,
            estimated_bloat_bytes: bloat_size,
            index_size_before_bytes: ondisk_size_before
          )

          duration = Benchmark.realtime do
            yield
          end

          index.reset

          logger.info(
            message: "Finished reindex of #{index}",
            index: index.identifier,
            table: index.tablename,
            estimated_bloat_bytes: bloat_size,
            index_size_before_bytes: ondisk_size_before,
            index_size_after_bytes: index.ondisk_size_bytes,
            duration_s: duration.round(2)
          )
        end

        def cleanup_dangling_indexes
          Gitlab::Database::PostgresIndex.match("#{TEMPORARY_INDEX_PATTERN}$").each do |lingering_index|
            # Example lingering index name: some_index_ccnew1

            # Example prefix: 'some_index'
            prefix = lingering_index.name.gsub(/#{TEMPORARY_INDEX_PATTERN}/, '')

            # Example suffix: '_ccnew1'
            suffix = lingering_index.name.match(/#{TEMPORARY_INDEX_PATTERN}/)[0]

            # Only remove if the lingering index name could have been chosen
            # as a result of a REINDEX operation (considering that PostgreSQL
            # truncates index names to 63 chars and adds a suffix).
            if index.name[0...PG_MAX_INDEX_NAME_LENGTH - suffix.length] == prefix
              remove_index(lingering_index)
            end
          end
        end

        def remove_index(index)
          logger.info("Removing dangling index #{index.identifier}")

          retries = Gitlab::Database::WithLockRetriesOutsideTransaction.new(
            timing_configuration: REMOVE_INDEX_RETRY_CONFIG,
            klass: self.class,
            logger: logger
          )

          retries.run(raise_on_exhaustion: false) do
            execute("DROP INDEX CONCURRENTLY IF EXISTS #{quote_table_name(index.schema)}.#{quote_table_name(index.name)}")
          end
        end

        def with_lock_retries(&block)
          arguments = { klass: self.class, logger: logger }
          Gitlab::Database::WithLockRetries.new(**arguments).run(raise_on_exhaustion: true, &block)
        end

        def set_statement_timeout
          execute("SET statement_timeout TO '%ds'" % STATEMENT_TIMEOUT)
          yield
        ensure
          execute('RESET statement_timeout')
        end

        delegate :execute, :quote_table_name, to: :connection
        def connection
          @connection ||= ActiveRecord::Base.connection
        end
      end
    end
  end
end
