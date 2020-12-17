# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      class ConcurrentReindex
        include Gitlab::Utils::StrongMemoize

        ReindexError = Class.new(StandardError)

        PG_IDENTIFIER_LENGTH = 63
        TEMPORARY_INDEX_PREFIX = 'tmp_reindex_'
        REPLACED_INDEX_PREFIX = 'old_reindex_'
        STATEMENT_TIMEOUT = 6.hours

        attr_reader :index, :logger

        def initialize(index, logger: Gitlab::AppLogger)
          @index = index
          @logger = logger
        end

        def perform
          raise ReindexError, 'UNIQUE indexes are currently not supported' if index.unique?
          raise ReindexError, 'partitioned indexes are currently not supported' if index.partitioned?
          raise ReindexError, 'indexes serving an exclusion constraint are currently not supported' if index.exclusion?
          raise ReindexError, 'index is a left-over temporary index from a previous reindexing run' if index.name.start_with?(TEMPORARY_INDEX_PREFIX, REPLACED_INDEX_PREFIX)

          logger.info "Starting reindex of #{index}"

          with_rebuilt_index do |replacement_index|
            swap_index(replacement_index)
          end
        end

        private

        def with_rebuilt_index
          if Gitlab::Database::PostgresIndex.find_by(schema: index.schema, name: replacement_index_name)
            logger.debug("dropping dangling index from previous run (if it exists): #{replacement_index_name}")
            remove_index(index.schema, replacement_index_name)
          end

          create_replacement_index_statement = index.definition
            .sub(/CREATE INDEX #{index.name}/, "CREATE INDEX CONCURRENTLY #{replacement_index_name}")

          logger.info("creating replacement index #{replacement_index_name}")
          logger.debug("replacement index definition: #{create_replacement_index_statement}")

          set_statement_timeout do
            connection.execute(create_replacement_index_statement)
          end

          replacement_index = Gitlab::Database::PostgresIndex.find_by(schema: index.schema, name: replacement_index_name)

          unless replacement_index.valid_index?
            message = 'replacement index was created as INVALID'
            logger.error("#{message}, cleaning up")
            raise ReindexError, "failed to reindex #{index}: #{message}"
          end

          # Some expression indexes (aka functional indexes)
          # require additional statistics. The existing statistics
          # are tightly bound to the original index. We have to
          # rebuild statistics for the new index before dropping
          # the original one.
          rebuild_statistics if index.expression?

          yield replacement_index
        ensure
          begin
            remove_index(index.schema, replacement_index_name)
          rescue => e
            logger.error(e)
          end
        end

        def swap_index(replacement_index)
          logger.info("swapping replacement index #{replacement_index} with #{index}")

          with_lock_retries do
            rename_index(index.schema, index.name, replaced_index_name)
            rename_index(replacement_index.schema, replacement_index.name, index.name)
            rename_index(index.schema, replaced_index_name, replacement_index.name)
          end
        end

        def rename_index(schema, old_index_name, new_index_name)
          connection.execute(<<~SQL)
            ALTER INDEX #{quote_table_name(schema)}.#{quote_table_name(old_index_name)}
            RENAME TO #{quote_table_name(new_index_name)}
          SQL
        end

        def remove_index(schema, name)
          logger.info("Removing index #{schema}.#{name}")

          set_statement_timeout do
            connection.execute(<<~SQL)
              DROP INDEX CONCURRENTLY
              IF EXISTS #{quote_table_name(schema)}.#{quote_table_name(name)}
            SQL
          end
        end

        def rebuild_statistics
          logger.info("rebuilding table statistics for #{index.schema}.#{index.tablename}")

          connection.execute(<<~SQL)
            ANALYZE #{quote_table_name(index.schema)}.#{quote_table_name(index.tablename)}
          SQL
        end

        def replacement_index_name
          @replacement_index_name ||= "#{TEMPORARY_INDEX_PREFIX}#{index.indexrelid}"
        end

        def replaced_index_name
          @replaced_index_name ||= "#{REPLACED_INDEX_PREFIX}#{index.indexrelid}"
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
