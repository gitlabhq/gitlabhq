# frozen_string_literal: true

module Gitlab
  module Database
    class AlterLegacyCellSequencesMaxValue
      MISSING_MAXVAL_MSG = 'maxval is required to alter sequence max value'
      # PostgreSQL's bigint max value (2^63 - 1 = 9223372036854775807).
      # Rails does not expose a built-in constant for this.
      # All sequences in our production and staging environments use this as their default max value.
      DEFAULT_MAX_VALUE = (2**63) - 1
      TRIGGER_NAME = 'alter_new_sequences_max_value'
      FUNCTION_NAME = 'alter_new_sequences_max_value'

      attr_reader :maxval, :connection, :sequence_names, :skip_trigger_install, :logger

      def initialize(maxval, connection, sequence_names: nil, skip_trigger_install: false, logger: Gitlab::AppLogger)
        raise MISSING_MAXVAL_MSG unless maxval.present? && maxval.to_i > 0

        @maxval = Integer(maxval)
        @connection = connection
        @logger = logger
        @sequence_names = Array(sequence_names)
        @skip_trigger_install = skip_trigger_install
      end

      def execute
        logger.info("Altering sequences max value to: #{maxval}")

        sequences.each do |sequence|
          next if sequence.seq_max == maxval

          with_lock_retries do
            alter_sequence_query = <<~SQL
              ALTER SEQUENCE #{connection.quote_table_name(sequence.seq_name)}
              MAXVALUE #{maxval}
            SQL

            connection.execute(alter_sequence_query)
          end
        end

        logger.info("Altered [#{sequences.pluck(:seq_name).join(',')}] max value.")

        return if sequence_names.present?

        connection.execute(alter_new_sequences_max_value_function)

        if skip_trigger_install
          logger.info("Skipping event trigger installation as SKIP_SEQUENCE_TRIGGER_INSTALL is set")
        else
          connection.execute(alter_new_sequences_max_value_trigger)
        end
      end

      def rollback
        logger.info("Rolling back sequences max value to default: #{DEFAULT_MAX_VALUE}")

        drop_event_trigger unless sequence_names.present?

        sequences.each do |sequence|
          next if sequence.seq_max == DEFAULT_MAX_VALUE

          with_lock_retries do
            alter_sequence_query = <<~SQL
              ALTER SEQUENCE #{connection.quote_table_name(sequence.seq_name)}
              MAXVALUE #{DEFAULT_MAX_VALUE}
            SQL

            connection.execute(alter_sequence_query)
          end
        end

        logger.info("Rolled back [#{sequences.pluck(:seq_name).join(',')}] max value to default.")
      end

      def drop_event_trigger
        connection.execute("DROP EVENT TRIGGER IF EXISTS #{connection.quote_table_name(TRIGGER_NAME)}")
        connection.execute("DROP FUNCTION IF EXISTS #{connection.quote_table_name(FUNCTION_NAME)}()")
      end

      def alter_new_sequences_max_value_function
        <<~SQL
          CREATE OR REPLACE FUNCTION #{connection.quote_table_name(FUNCTION_NAME)}()
            RETURNS event_trigger
          AS $$
          DECLARE
            command_record RECORD;
            sequence_name text;
            sequence_data_type text;
            current_minval BIGINT;
            current_maxval BIGINT;
            current_last_value BIGINT;
          BEGIN
            FOR command_record IN SELECT * FROM pg_event_trigger_ddl_commands () LOOP
              -- CREATE TABLE, ALTER TABLE will fire ALTER SEQUENCE event when SERIAL, BIGSERIAL IDs are used.
              IF command_record.command_tag IN ('CREATE SEQUENCE', 'ALTER SEQUENCE') THEN
                sequence_name := substring(command_record.object_identity FROM '([^.]+)$');

                SELECT data_type::text, min_value, max_value, last_value
                INTO sequence_data_type, current_minval, current_maxval, current_last_value
                FROM pg_sequences
                WHERE sequencename = sequence_name;

                -- Skip integer/smallint sequences as their max value (2^31-1) cannot hold our maxval.
                IF sequence_data_type != 'bigint' THEN
                  CONTINUE;
                END IF;

                -- Skip if sequence already has the correct max value (also prevents recursive trigger calls).
                IF current_maxval = #{maxval} THEN
                  CONTINUE;
                END IF;

                -- Only alter sequences whose minval is below our maxval.
                -- Some sequences use a small offset for reserved IDs (e.g. minval=1001),
                -- so we cannot assume minval=1. Sequences bumped to a higher range via
                -- increase_sequences_range will have a (new) current_minval >= (previous) maxval and are left alone.
                IF current_minval < #{maxval} THEN
                  EXECUTE FORMAT('ALTER SEQUENCE %I MAXVALUE %s',
                    sequence_name, #{maxval});
                END IF;
              END IF;
            END LOOP;
          END;
          $$ LANGUAGE plpgsql;
        SQL
      end

      def alter_new_sequences_max_value_trigger
        <<~SQL
          DROP EVENT TRIGGER IF EXISTS #{connection.quote_table_name(TRIGGER_NAME)};

          CREATE EVENT TRIGGER #{connection.quote_table_name(TRIGGER_NAME)} ON ddl_command_end
            WHEN TAG IN ('CREATE TABLE', 'ALTER TABLE', 'CREATE SEQUENCE', 'ALTER SEQUENCE')
          EXECUTE FUNCTION #{connection.quote_table_name(FUNCTION_NAME)}();
        SQL
      end

      private

      def sequences
        if sequence_names.present?
          Gitlab::Database::PostgresSequence.where(seq_name: sequence_names)
        else
          Gitlab::Database::PostgresSequence.all
        end
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
