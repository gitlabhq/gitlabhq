# frozen_string_literal: true

module Gitlab
  module Database
    class AlterCellSequencesRange
      MISSING_LIMIT_MSG = 'minval and maxval are required to alter sequence range'

      attr_reader :minval, :maxval, :connection, :sequence_names, :logger

      def initialize(minval, maxval, connection, sequence_names: nil, logger: Gitlab::AppLogger)
        raise MISSING_LIMIT_MSG unless minval.present? && maxval.present?

        @minval = minval
        @maxval = maxval
        @connection = connection
        @logger = logger
        @sequence_names = Array(sequence_names)
      end

      def execute
        logger.info("Altering sequences with minval: #{minval}, maxval: #{maxval}")

        sequences.each do |sequence|
          # Skip if sequence already has the correct boundaries
          next if sequence.seq_min == minval && sequence.seq_max == maxval

          with_lock_retries do
            if minval > sequence.last_value.to_i
              # New cell case: sequence hasn't reached minval yet, safe to restart
              alter_sequence_query = <<~SQL
                ALTER SEQUENCE #{sequence.seq_name}
                START #{minval} RESTART #{minval} MINVALUE #{minval} MAXVALUE #{maxval}
              SQL
            else
              # Legacy cell: sequence is already past minval, only set boundaries
              logger.info(
                "Sequence #{sequence.seq_name} already >= minval, skipping RESTART"
              )

              alter_sequence_query = <<~SQL
                ALTER SEQUENCE #{sequence.seq_name}
                MINVALUE #{minval} MAXVALUE #{maxval}
              SQL
            end

            connection.execute(alter_sequence_query)
          end
        end

        logger.info("Altered [#{sequences.pluck(:seq_name).join(',')}] range.")

        return if sequence_names.present? # Below event trigger is needed only while loading the Db.

        connection.execute(alter_new_sequences_range_function)
        connection.execute(alter_new_sequences_range_trigger)
      end

      def alter_new_sequences_range_function
        <<~SQL
          CREATE OR REPLACE FUNCTION alter_new_sequences_range()
            RETURNS event_trigger
          AS $$
          DECLARE
            command_record RECORD;
            sequence_name text;
            current_minval BIGINT;
            current_maxval BIGINT;
            current_last_value BIGINT;
          BEGIN
            FOR command_record IN SELECT * FROM pg_event_trigger_ddl_commands () LOOP
              -- CREATE TABLE, ALTER TABLE will fire ALTER SEQUENCE event when SERIAL, BIGSERIAL IDs are used.
              IF command_record.command_tag IN ('CREATE SEQUENCE', 'ALTER SEQUENCE') THEN
                sequence_name := substring(command_record.object_identity FROM '([^.]+)$');

                SELECT min_value, max_value, last_value INTO current_minval, current_maxval, current_last_value FROM pg_sequences
                WHERE sequencename = sequence_name;

                -- On bumping sequence ranges using gitlab:db:increase_sequences_range, new ranges will always be
                -- greater than the existing ones. The below check catches the default minval (1) and updates accordingly.
                -- Skip if sequence already has the correct boundaries (also prevents recursive trigger calls)
                IF current_minval = #{minval} AND current_maxval = #{maxval} THEN
                  CONTINUE;
                END IF;

                -- Only alter sequences whose current minval is <= our target minval.
                -- This ensures new sequences (default minval=1) and legacy cell sequences get altered,
                -- but sequences already bumped to a higher range via increase_sequences_range are left alone.
                IF current_minval <= #{minval} THEN
                  IF current_last_value IS NULL OR #{minval} > current_last_value THEN
                    -- New cell: sequence hasn't reached minval yet, safe to restart
                    EXECUTE FORMAT('ALTER SEQUENCE %I START %s RESTART %s MINVALUE %s MAXVALUE %s',
                      sequence_name, #{minval}, #{minval}, #{minval}, #{maxval});
                  ELSE
                    -- Legacy cell: sequence is already past minval, only set boundaries
                    EXECUTE FORMAT('ALTER SEQUENCE %I MINVALUE %s MAXVALUE %s',
                      sequence_name, #{minval}, #{maxval});
                  END IF;
                END IF;
              END IF;
            END LOOP;
          END;
          $$ LANGUAGE plpgsql;
        SQL
      end

      def alter_new_sequences_range_trigger
        <<~SQL
          DROP EVENT TRIGGER IF EXISTS alter_new_sequences_range;

          CREATE EVENT TRIGGER alter_new_sequences_range ON ddl_command_end
            WHEN TAG IN ('CREATE TABLE', 'ALTER TABLE', 'CREATE SEQUENCE', 'ALTER SEQUENCE')
          EXECUTE FUNCTION alter_new_sequences_range();
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
