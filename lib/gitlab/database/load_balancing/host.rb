# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # A single database host used for load balancing.
      class Host
        attr_reader :pool, :last_checked_at, :intervals, :load_balancer, :host, :port

        delegate :connection, :release_connection, :enable_query_cache!, :disable_query_cache!, :query_cache_enabled, to: :pool

        CONNECTION_ERRORS =
          if defined?(PG)
            [
              ActionView::Template::Error,
              ActiveRecord::StatementInvalid,
              PG::Error
            ].freeze
          else
            [
              ActionView::Template::Error,
              ActiveRecord::StatementInvalid
            ].freeze
          end

        # host - The address of the database.
        # load_balancer - The LoadBalancer that manages this Host.
        def initialize(host, load_balancer, port: nil)
          @host = host
          @port = port
          @load_balancer = load_balancer
          @pool = Database.create_connection_pool(LoadBalancing.pool_size, host, port)
          @online = true
          @last_checked_at = Time.zone.now

          interval = LoadBalancing.replica_check_interval
          @intervals = (interval..(interval * 2)).step(0.5).to_a
        end

        # Disconnects the pool, once all connections are no longer in use.
        #
        # timeout - The time after which the pool should be forcefully
        #           disconnected.
        def disconnect!(timeout = 120)
          start_time = Metrics::System.monotonic_time

          while (Metrics::System.monotonic_time - start_time) <= timeout
            break if pool.connections.none?(&:in_use?)

            sleep(2)
          end

          pool.disconnect!
        end

        def offline!
          LoadBalancing::Logger.warn(
            event: :host_offline,
            message: 'Marking host as offline',
            db_host: @host,
            db_port: @port
          )

          @online = false
          @pool.disconnect!
        end

        # Returns true if the host is online.
        def online?
          return @online unless check_replica_status?

          refresh_status

          if @online
            LoadBalancing::Logger.info(
              event: :host_online,
              message: 'Host is online after replica status check',
              db_host: @host,
              db_port: @port
            )
          else
            LoadBalancing::Logger.warn(
              event: :host_offline,
              message: 'Host is offline after replica status check',
              db_host: @host,
              db_port: @port
            )
          end

          @online
        rescue *CONNECTION_ERRORS
          offline!
          false
        end

        def refresh_status
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
          if (lag_time = replication_lag_time)
            lag_time <= LoadBalancing.max_replication_lag_time
          else
            false
          end
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
          if (lag_size = replication_lag_size)
            lag_size <= LoadBalancing.max_replication_difference
          else
            false
          end
        end

        # Returns the replication lag time of this secondary in seconds as a
        # float.
        #
        # This method will return nil if no lag time could be calculated.
        def replication_lag_time
          row = query_and_release('SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()))::float as lag')

          row['lag'].to_f if row.any?
        end

        # Returns the number of bytes this secondary is lagging behind the
        # primary.
        #
        # This method will return nil if no lag size could be calculated.
        def replication_lag_size
          location = connection.quote(primary_write_location)
          row = query_and_release(<<-SQL.squish)
            SELECT pg_wal_lsn_diff(#{location}, pg_last_wal_replay_lsn())::float
              AS diff
          SQL

          row['diff'].to_i if row.any?
        rescue *CONNECTION_ERRORS
          nil
        end

        def primary_write_location
          load_balancer.primary_write_location
        ensure
          load_balancer.release_primary_connection
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
          string = connection.quote(location)

          # In case the host is a primary pg_last_wal_replay_lsn/pg_last_xlog_replay_location() returns
          # NULL. The recovery check ensures we treat the host as up-to-date in
          # such a case.
          query = <<-SQL.squish
            SELECT NOT pg_is_in_recovery()
              OR pg_wal_lsn_diff(pg_last_wal_replay_lsn(), #{string}) >= 0
              AS result
          SQL

          row = query_and_release(query)

          ::Gitlab::Utils.to_boolean(row['result'])
        rescue *CONNECTION_ERRORS
          false
        end

        def query_and_release(sql)
          connection.select_all(sql).first || {}
        rescue StandardError
          {}
        ensure
          release_connection
        end
      end
    end
  end
end
