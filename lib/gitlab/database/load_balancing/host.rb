# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # A single database host used for load balancing.
      class Host
        attr_reader :pool, :last_checked_at, :intervals, :load_balancer, :host, :port

        delegate :connection, :release_connection, :enable_query_cache!, :disable_query_cache!, :query_cache_enabled, to: :pool

        CONNECTION_ERRORS = [
          ActionView::Template::Error,
          ActiveRecord::StatementInvalid,
          ActiveRecord::ConnectionNotEstablished,
          ActiveRecord::StatementTimeout,
          PG::Error
        ].freeze

        # This query checks that the current user has permissions before we try and query logical replication status. We
        # also only allow >= PG14 because these views are only accessible to superuser before PG14 even if the
        # has_table_privilege says otherwise.
        CAN_TRACK_LOGICAL_LSN_QUERY = <<~SQL.squish.freeze
          SELECT
            has_table_privilege('pg_replication_origin_status', 'select')
            AND
            has_function_privilege('pg_show_replication_origin_status()', 'execute')
            AND current_setting('server_version_num', true)::int >= 140000
            AS allowed
        SQL

        # The following is necessary to handle a mix of logical and physical replicas. We assume that if they have
        # pg_replication_origin_status then they are a logical replica. In a logical replica we need to use
        # `remote_lsn` rather than `pg_last_wal_replay_lsn` in order for our LSN to be comparable to the source
        # cluster. This logic would be broken if we have 2 logical subscriptions or if we have a logical subscription
        # in the source primary cluster. Read more at https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121621
        LATEST_LSN_WITH_LOGICAL_QUERY = <<~SQL.squish.freeze
          CASE
          WHEN (SELECT TRUE FROM pg_replication_origin_status) THEN
            (SELECT remote_lsn FROM pg_replication_origin_status)
          WHEN pg_is_in_recovery() THEN
            pg_last_wal_replay_lsn()
          ELSE
            pg_current_wal_insert_lsn()
          END
        SQL

        LATEST_LSN_WITHOUT_LOGICAL_QUERY = <<~SQL.squish.freeze
          CASE
          WHEN pg_is_in_recovery() THEN
            pg_last_wal_replay_lsn()
          ELSE
            pg_current_wal_insert_lsn()
          END
        SQL

        REPLICATION_LAG_QUERY = <<~SQL.squish.freeze
          SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()))::float as lag
        SQL

        # host - The address of the database.
        # load_balancer - The LoadBalancer that manages this Host.
        def initialize(host, load_balancer, port: nil)
          @host = host
          @port = port
          @load_balancer = load_balancer
          @pool = load_balancer.create_replica_connection_pool(
            load_balancer.configuration.pool_size,
            host,
            port
          )
          @online = true
          @last_checked_at = Time.zone.now
          @lag_time = nil
          @lag_size = nil

          # Randomly somewhere in between interval and 2*interval we'll refresh the status of the host
          interval = load_balancer.configuration.replica_check_interval
          @intervals = (interval..(interval * 2)).step(0.5).to_a
        end

        # Disconnects the pool, once all connections are no longer in use.
        #
        # timeout - The time after which the pool should be forcefully
        #           disconnected.
        def disconnect!(timeout: 120)
          start_time = ::Gitlab::Metrics::System.monotonic_time

          while (::Gitlab::Metrics::System.monotonic_time - start_time) <= timeout
            return if try_disconnect

            sleep(2)
          end

          force_disconnect!
        end

        # Attempt to disconnect the pool if all connections are no longer in use.
        # Returns true if the pool was disconnected, false if not.
        def try_disconnect
          if pool.connections.none?(&:in_use?)
            pool_disconnect!
            return true
          end

          false
        end

        def force_disconnect!
          pool_disconnect!
        end

        def pool_disconnect!
          return pool.disconnect! if ::Gitlab.next_rails?

          pool.disconnect_without_verify!
        end

        def offline!
          ::Gitlab::Database::LoadBalancing::Logger.warn(
            event: :host_offline,
            message: 'Marking host as offline',
            db_host: @host,
            db_port: @port
          )

          @online = false
          pool_disconnect!
        end

        # Returns true if the host is online.
        def online?
          return @online unless check_replica_status?

          was_online = @online
          refresh_status

          # Log that the host came back online if it was previously offline
          if @online && !was_online
            ::Gitlab::Database::LoadBalancing::Logger.info(
              event: :host_online,
              message: 'Host is online after replica status check',
              db_host: @host,
              db_port: @port,
              lag_time: @lag_time,
              lag_size: @lag_size
            )
          # Always log if the host goes offline
          elsif !@online
            ::Gitlab::Database::LoadBalancing::Logger.warn(
              event: :host_offline,
              message: 'Host is offline after replica status check',
              db_host: @host,
              db_port: @port,
              lag_time: @lag_time,
              lag_size: @lag_size
            )
          end

          @online
        rescue *CONNECTION_ERRORS
          offline!
          false
        end

        def refresh_status
          @latest_lsn_query = nil # Periodically clear the cached @latest_lsn_query value in case permissions change
          @online = replica_is_up_to_date?
          @last_checked_at = Time.zone.now
        end

        def check_replica_status?
          (Time.zone.now - last_checked_at) >= intervals.sample
        end

        def replica_is_up_to_date?
          replication_lag_below_threshold? || data_is_recent_enough?
        end

        def replication_lag_below_threshold?
          @lag_time = replication_lag_time
          return false unless @lag_time
          return true if @lag_time <= load_balancer.configuration.max_replication_lag_time

          if ignore_replication_lag_time?
            ::Gitlab::Database::LoadBalancing::Logger.info(
              event: :replication_lag_ignored,
              lag_time: @lag_time,
              message: 'Replication lag is treated as low because of load_balancer_ignore_replication_lag_time feature flag'
            )

            return true
          end

          if double_replication_lag_time? && @lag_time <= (load_balancer.configuration.max_replication_lag_time * 2)
            ::Gitlab::Database::LoadBalancing::Logger.info(
              event: :replication_lag_below_double,
              lag_time: @lag_time,
              message: 'Replication lag is treated as low because of load_balancer_double_replication_lag_time feature flag'
            )

            return true
          end

          false
        end

        # Returns true if the replica has replicated enough data to be useful.
        def data_is_recent_enough?
          # It's possible for a replica to not replay WAL data for a while,
          # despite being up to date. This can happen when a primary does not
          # receive any writes for a while.
          #
          # To prevent this from happening we check if the lag size (in bytes)
          # of the replica is small enough for the replica to be useful. We
          # only do this if we haven't replicated in a while so we only need
          # to connect to the primary when truly necessary.
          if (@lag_size = replication_lag_size)
            @lag_size <= load_balancer.configuration.max_replication_difference
          else
            false
          end
        end

        # Returns the replication lag time of this secondary in seconds as a
        # float.
        #
        # This method will return nil if no lag time could be calculated.
        def replication_lag_time
          row = query_and_release(REPLICATION_LAG_QUERY)

          row['lag'].to_f if row.any?
        end

        # Returns the number of bytes this secondary is lagging behind the
        # primary.
        #
        # This method will return nil if no lag size could be calculated.
        def replication_lag_size(location = primary_write_location)
          location = connection.quote(location)

          row = query_and_release(<<-SQL.squish)
            SELECT pg_wal_lsn_diff(#{location}, (#{latest_lsn_query}))::float AS diff
          SQL

          row['diff'].to_i if row.any?
        rescue *CONNECTION_ERRORS
          nil
        end

        def primary_write_location
          load_balancer.primary_write_location
        end

        def database_replica_location
          row = query_and_release(<<-SQL.squish)
            SELECT pg_last_wal_replay_lsn()::text AS location
          SQL

          row['location'] if row.any?
        rescue *CONNECTION_ERRORS
          nil
        end

        # Returns true if this host has caught up to the given transaction
        # write location.
        #
        # location - The transaction write location as reported by a primary.
        def caught_up?(location)
          lag = replication_lag_size(location)
          lag.present? && lag.to_i <= 0
        end

        def query_and_release(...)
          if low_timeout_for_host_queries?
            query_and_release_fast_timeout(...)
          else
            query_and_release_old(...)
          end
        end

        def query_and_release_old(sql)
          connection.select_all(sql).first || {}
        rescue StandardError
          {}
        ensure
          release_connection
        end

        def query_and_release_fast_timeout(sql)
          # If we "set local" the timeout in a transaction that was already open we would taint the outer
          # transaction with that timeout.
          # However, we don't ever run transactions on replicas, and we only do these health checks on replicas.
          # Double-check that we're not in a transaction, but this path should never happen.
          if connection.transaction_open?
            Gitlab::Database::LoadBalancing::Logger.warn(
              event: :health_check_in_transaction,
              message: "Attempt to run a health check query inside of a transaction"
            )
            return query_and_release_old(sql)
          end

          begin
            connection.transaction do
              connection.exec_query("SET LOCAL statement_timeout TO '100ms';")
              connection.select_all(sql).first || {}
            end
          rescue StandardError
            {}
          ensure
            release_connection
          end
        end

        private

        def can_track_logical_lsn?
          row = query_and_release(CAN_TRACK_LOGICAL_LSN_QUERY)

          ::Gitlab::Utils.to_boolean(row['allowed'])
        rescue *CONNECTION_ERRORS
          false
        end

        # The LATEST_LSN_WITH_LOGICAL query requires permissions that may not be present in self-managed configurations.
        # We fallback gracefully to the query that does not correctly handle logical replicas for such configurations.
        def latest_lsn_query
          @latest_lsn_query ||= can_track_logical_lsn? ? LATEST_LSN_WITH_LOGICAL_QUERY : LATEST_LSN_WITHOUT_LOGICAL_QUERY
        end

        def ignore_replication_lag_time?
          Feature.enabled?(:load_balancer_ignore_replication_lag_time, type: :ops)
        end

        def double_replication_lag_time?
          Feature.enabled?(:load_balancer_double_replication_lag_time, type: :ops)
        end

        def low_timeout_for_host_queries?
          Feature.enabled?(:load_balancer_low_statement_timeout, Feature.current_pod)
        end
      end
    end
  end
end
