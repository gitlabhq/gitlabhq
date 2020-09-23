# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      class ConcurrentReindex
        include Gitlab::Utils::StrongMemoize
        include MigrationHelpers

        ReindexError = Class.new(StandardError)

        PG_IDENTIFIER_LENGTH = 63
        TEMPORARY_INDEX_PREFIX = 'tmp_reindex_'
        REPLACED_INDEX_PREFIX = 'old_reindex_'

        attr_reader :index, :logger

        def initialize(index, logger: Gitlab::AppLogger)
          @index = index
          @logger = logger
        end

        def perform
          raise ReindexError, 'UNIQUE indexes are currently not supported' if index.unique?

          with_rebuilt_index do |replacement_index|
            swap_index(replacement_index)
          end
        end

        private

        def with_rebuilt_index
          logger.debug("dropping dangling index from previous run (if it exists): #{replacement_index_name}")
          remove_replacement_index

          create_replacement_index_statement = index.definition
            .sub(/CREATE INDEX/, 'CREATE INDEX CONCURRENTLY')
            .sub(/#{index.name}/, replacement_index_name)

          logger.info("creating replacement index #{replacement_index_name}")
          logger.debug("replacement index definition: #{create_replacement_index_statement}")

          disable_statement_timeout do
            connection.execute(create_replacement_index_statement)
          end

          replacement_index = Index.find_with_schema("#{index.schema}.#{replacement_index_name}")

          unless replacement_index.valid?
            message = 'replacement index was created as INVALID'
            logger.error("#{message}, cleaning up")
            raise ReindexError, "failed to reindex #{index}: #{message}"
          end

          yield replacement_index

        rescue Gitlab::Database::WithLockRetries::AttemptsExhaustedError => e
          logger.error('failed to obtain the required database locks to swap the indexes, cleaning up')
          raise ReindexError, e.message
        rescue ActiveRecord::ActiveRecordError, PG::Error => e
          logger.error("database error while attempting reindex of #{index}: #{e.message}")
          raise ReindexError, e.message
        ensure
          logger.info("dropping unneeded replacement index: #{replacement_index_name}")
          remove_replacement_index
        end

        def swap_index(replacement_index)
          replaced_index_name = constrained_index_name(REPLACED_INDEX_PREFIX)

          logger.info("swapping replacement index #{replacement_index} with #{index}")

          with_lock_retries do
            rename_index(index.name, replaced_index_name)
            rename_index(replacement_index.name, index.name)
            rename_index(replaced_index_name, replacement_index.name)
          end
        end

        def rename_index(old_index_name, new_index_name)
          connection.execute("ALTER INDEX #{old_index_name} RENAME TO #{new_index_name}")
        end

        def remove_replacement_index
          disable_statement_timeout do
            connection.execute("DROP INDEX CONCURRENTLY IF EXISTS #{replacement_index_name}")
          end
        end

        def replacement_index_name
          @replacement_index_name ||= constrained_index_name(TEMPORARY_INDEX_PREFIX)
        end

        def constrained_index_name(prefix)
          "#{prefix}#{index.name}".slice(0, PG_IDENTIFIER_LENGTH)
        end

        def with_lock_retries(&block)
          arguments = { klass: self.class, logger: logger }

          Gitlab::Database::WithLockRetries.new(**arguments).run(raise_on_exhaustion: true, &block)
        end

        delegate :execute, to: :connection
        def connection
          @connection ||= ActiveRecord::Base.connection
        end
      end
    end
  end
end
