# frozen_string_literal: true

# In Rails 7.0, whenever `ConnectionPool#disconnect!` is called, each
# connection in the `@available` queue is acquired by the thread and
# verified with a SQL `;` query. If the verification fails, then Rails
# will attempt a reconnect for all those connections in the pool. This
# reconnection can cause unnecessary database connection saturation and
# result in a flood of SET statements on a PostgreSQL host.
#
# Rails 7.1 has fixed this in https://github.com/rails/rails/pull/44576, but
# until we upgrade this patch disables this verification step.
module Gitlab
  module Patch
    # rubocop:disable Cop/AvoidReturnFromBlocks -- This patches an upstream class
    # rubocop:disable Cop/LineBreakAfterGuardClauses -- This patches an upstream class
    # rubocop:disable Cop/LineBreakAroundConditionalBlock -- This patches an upstream class
    # rubocop:disable Gitlab/ModuleWithInstanceVariables -- This patches an upstream class
    # rubocop:disable Layout/EmptyLineAfterGuardClause -- This patches an upstream class
    # rubocop:disable Lint/RescueException -- This patches an upstream class
    # rubocop:disable Style/IfUnlessModifier -- This patches an upstream class
    module ActiveRecordConnectionPool
      # Many of these methods were copied directly from
      # https://github.com/rails/rails/blob/v7.0.8.4/activerecord/lib/active_record/connection_adapters/abstract/connection_pool.rb.
      # Public methods have the `_without_verify` suffix appended, and
      # private methods have the `_no_verify` suffix appended.

      # Disconnects all connections in the pool, and clears the pool.
      #
      # Raises:
      # - ActiveRecord::ExclusiveConnectionTimeoutError if unable to gain ownership of all
      #   connections in the pool within a timeout interval (default duration is
      #   <tt>spec.db_config.checkout_timeout * 2</tt> seconds).
      def disconnect_without_verify(raise_on_acquisition_timeout = true)
        with_exclusively_acquired_all_connections_no_verify(raise_on_acquisition_timeout) do
          synchronize do
            @connections.each do |conn|
              if conn.in_use?
                conn.steal!
                checkin conn
              end
              conn.disconnect!
            end
            @connections = []
            @available.clear
          end
        end
      end

      def disconnect_without_verify!
        disconnect_without_verify(false)
      end

      private

      # Take control of all existing connections so a "group" action such as
      # reload/disconnect can be performed safely. It is no longer enough to
      # wrap it in +synchronize+ because some pool's actions are allowed
      # to be performed outside of the main +synchronize+ block.
      def with_exclusively_acquired_all_connections_no_verify(raise_on_acquisition_timeout = true)
        with_new_connections_blocked do
          attempt_to_checkout_all_existing_connections_no_verify(raise_on_acquisition_timeout)
          yield
        end
      end

      def attempt_to_checkout_all_existing_connections_no_verify(raise_on_acquisition_timeout = true)
        collected_conns = synchronize do
          # account for our own connections
          @connections.select { |conn| conn.owner == Thread.current }
        end

        newly_checked_out = []
        timeout_time      = Process.clock_gettime(Process::CLOCK_MONOTONIC) + (@checkout_timeout * 2)

        @available.with_a_bias_for(Thread.current) do
          loop do
            synchronize do
              return if collected_conns.size == @connections.size && @now_connecting == 0
              remaining_timeout = timeout_time - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              remaining_timeout = 0 if remaining_timeout < 0
              conn = checkout_for_exclusive_access_no_verify(remaining_timeout)
              collected_conns   << conn
              newly_checked_out << conn
            end
          end
        end
      rescue ActiveRecord::ExclusiveConnectionTimeoutError
        # <tt>raise_on_acquisition_timeout == false</tt> means we are directed to ignore any
        # timeouts and are expected to just give up: we've obtained as many connections
        # as possible, note that in a case like that we don't return any of the
        # +newly_checked_out+ connections.

        if raise_on_acquisition_timeout
          release_newly_checked_out = true
          raise
        end
      rescue Exception # if something else went wrong
        # this can't be a "naked" rescue, because we have should return conns
        # even for non-StandardErrors
        release_newly_checked_out = true
        raise
      ensure
        if release_newly_checked_out && newly_checked_out
          # releasing only those conns that were checked out in this method, conns
          # checked outside this method (before it was called) are not for us to release
          newly_checked_out.each { |conn| checkin(conn) }
        end
      end

      #--
      # Must be called in a synchronize block.
      def checkout_for_exclusive_access_no_verify(checkout_timeout)
        checkout_no_verify(checkout_timeout)
      rescue ActiveRecord::ConnectionTimeoutError
        # this block can't be easily moved into attempt_to_checkout_all_existing_connections's
        # rescue block, because doing so would put it outside of synchronize section, without
        # being in a critical section thread_report might become inaccurate
        msg = "could not obtain ownership of all database connections in #{checkout_timeout} seconds"

        thread_report = []
        @connections.each do |conn|
          unless conn.owner == Thread.current
            thread_report << "#{conn} is owned by #{conn.owner}"
          end
        end

        msg << " (#{thread_report.join(', ')})" if thread_report.any?

        raise ActiveRecord::ExclusiveConnectionTimeoutError, msg
      end

      # Check-out a database connection from the pool, indicating that you want
      # to use it. You should call #checkin when you no longer need this.
      #
      # This is done by either returning and leasing existing connection, or by
      # creating a new connection and leasing it.
      #
      # If all connections are leased and the pool is at capacity (meaning the
      # number of currently leased connections is greater than or equal to the
      # size limit set), an ActiveRecord::ConnectionTimeoutError exception will be raised.
      #
      # Returns: an AbstractAdapter object.
      #
      # Raises:
      # - ActiveRecord::ConnectionTimeoutError no connection can be obtained from the pool.
      def checkout_no_verify(checkout_timeout = @checkout_timeout)
        checkout_with_no_verify(acquire_connection(checkout_timeout))
      end

      def checkout_with_no_verify(c) # rubocop:disable Naming/MethodParameterName -- This is an upstream method
        c._run_checkout_callbacks {} # rubocop:disable Lint/EmptyBlock -- Added to be safe to preserve previous behavior
        c
      rescue # rubocop:disable Style/RescueStandardError -- This is in the upstream code
        remove c
        c.disconnect!
        raise
      end
    end
    # rubocop:enable Cop/AvoidReturnFromBlocks
    # rubocop:enable Cop/LineBreakAfterGuardClauses
    # rubocop:enable Cop/LineBreakAroundConditionalBlock
    # rubocop:enable Gitlab/ModuleWithInstanceVariables
    # rubocop:enable Layout/EmptyLineAfterGuardClause
    # rubocop:enable Lint/RescueException -- This patches an upstream class
    # rubocop:enable Style/IfUnlessModifier
  end
end
