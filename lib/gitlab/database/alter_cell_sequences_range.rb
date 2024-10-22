# frozen_string_literal: true

module Gitlab
  module Database
    class AlterCellSequencesRange
      MISSING_LIMIT_MSG = 'Either minval or maxval is required to alter sequence range'

      attr_reader :minval, :maxval, :connection, :logger

      def initialize(minval, maxval, connection, logger: Gitlab::AppLogger)
        raise MISSING_LIMIT_MSG unless minval.present? || maxval.present?

        @minval = minval
        @maxval = maxval
        @connection = connection
        @logger = logger
      end

      def execute
        sequences.each do |sequence|
          with_lock_retries do
            connection.execute(alter_sequence_query(sequence))
          end
        end
      end

      private

      def sequences
        sequences_sql = "SELECT DISTINCT(sequencename) FROM pg_sequences WHERE schemaname = 'public'"
        connection.select_rows(sequences_sql).flatten
      end

      def alter_sequence_query(sequence_name)
        sql = "ALTER SEQUENCE #{sequence_name}"
        sql += " START #{minval} RESTART #{minval} MINVALUE #{minval}" if minval.present?
        return sql unless maxval.present?

        sql + " MAXVALUE #{maxval}"
      end

      def with_lock_retries(&)
        Gitlab::Database::WithLockRetries.new(
          connection: connection,
          logger: logger
        ).run(raise_on_exhaustion: false, &)
      end
    end
  end
end
