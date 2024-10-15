# frozen_string_literal: true

module Gitlab
  module Database
    module Transaction
      class Observer
        INSTRUMENTED_STATEMENTS = %w[BEGIN SAVEPOINT ROLLBACK RELEASE].freeze
        LONGEST_COMMAND_LENGTH = 'ROLLBACK TO SAVEPOINT'.length
        START_COMMENT = '/*'
        END_COMMENT = '*/'

        def self.instrument_transactions(cmd, event)
          connection = event.payload[:connection]
          manager = connection&.transaction_manager
          return unless manager.respond_to?(:transaction_context)

          context = manager.transaction_context
          return if context.nil?

          if cmd.start_with?('BEGIN')
            context.set_start_time
            context.set_depth(0)
            context.track_sql(event.payload[:sql])
            context.initialize_external_http_tracking
          elsif cmd.start_with?('SAVEPOINT', 'EXCEPTION')
            context.set_depth(manager.open_transactions)
            context.increment_savepoints
            context.track_backtrace(caller)
          elsif cmd.start_with?('ROLLBACK TO SAVEPOINT')
            context.increment_rollbacks
          elsif cmd.start_with?('RELEASE SAVEPOINT ')
            context.increment_releases
          end
        end

        def self.register!
          ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
            sql = event.payload[:sql].to_s
            cmd = extract_sql_command(sql)

            if cmd.start_with?(*INSTRUMENTED_STATEMENTS)
              self.instrument_transactions(cmd, event)
            end
          end
        end

        def self.extract_sql_command(sql)
          return sql unless sql.start_with?(START_COMMENT)

          index = sql.index(END_COMMENT)

          return sql unless index

          # /* comment */ SELECT
          #
          # We offset using a position of the end comment + 1 character to
          # accomodate a space between Marginalia comment and a SQL statement.
          offset = index + END_COMMENT.length + 1

          # Avoid duplicating the entire string. This isn't optimized to
          # strip extra spaces, but we assume that this doesn't happen
          # for performance reasons.
          sql[offset..offset + LONGEST_COMMAND_LENGTH]
        end
      end
    end
  end
end
