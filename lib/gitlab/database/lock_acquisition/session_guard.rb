# frozen_string_literal: true

module Gitlab
  module Database
    module LockAcquisition
      # Manages the watcher's borrowed database connection.
      #
      # The watcher changes two session-level settings on it: a 500ms
      # statement timeout so no poll can ever hang, and an application_name
      # so the session is identifiable in pg_stat_activity. Rails does NOT
      # reset session settings when a connection returns to the pool, so
      # this class owns both directions: applying the settings before any
      # poll runs, and giving the connection back either restored to its
      # original settings or removed from the pool entirely. A killed
      # thread or a failed restore leaves the session in an unknown state;
      # such connections are never handed to the next user.
      class SessionGuard
        # Both steps must run even when either raises: a connection that
        # cannot be deregistered from the pool must still be closed. Shared
        # with Protection's fallback path, which enforces the same contract.
        def self.remove_and_disconnect(pool, connection)
          pool.remove(connection)
        rescue StandardError
          nil
        ensure
          begin
            connection.disconnect!
          rescue StandardError
            nil
          end
        end

        def initialize(pool:)
          @pool = pool
        end

        def checkout
          pool.checkout
        end

        def harden(connection)
          # Captured for restore: RESET would land on the server default
          # (often 0), not the session value database.yml applies via
          # SET SESSION, so the pooled connection would go back unbounded.
          @original_statement_timeout = connection.select_value('SHOW statement_timeout')

          connection.execute("SET application_name = 'lock_acquisition_watcher'")
          connection.execute("SET statement_timeout = '#{Watcher::STATEMENT_TIMEOUT}'")
        end

        # Fail closed: a partially re-established session (reconnected but
        # missing the 500ms bound) must never poll. statement_timeout comes
        # first, and any failure propagates to the caller's degradation
        # path.
        def reassert(connection)
          connection.execute("SET statement_timeout = '#{Watcher::STATEMENT_TIMEOUT}'")
          connection.execute("SET application_name = 'lock_acquisition_watcher'")
        end

        def release(connection, discard:)
          if discard || !reset_session(connection)
            self.class.remove_and_disconnect(pool, connection)
          else
            pool.checkin(connection)
          end
        rescue StandardError
          nil
        end

        private

        attr_reader :pool

        def reset_session(connection)
          if @original_statement_timeout
            connection.execute("SET statement_timeout = #{connection.quote(@original_statement_timeout)}")
          end

          connection.execute('RESET application_name')
          true
        rescue StandardError
          false
        end
      end
    end
  end
end
