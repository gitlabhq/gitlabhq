module Gitlab
  module Database
    module LoadBalancing
      # A single database host used for load balancing.
      class Host
        attr_reader :pool, :last_checked_at, :intervals, :load_balancer

        delegate :connection, :release_connection, to: :pool

        # host - The address of the database.
        # load_balancer - The LoadBalancer that manages this Host.
        def initialize(host, load_balancer)
          @host = host
          @load_balancer = load_balancer
          @pool = Database.create_connection_pool(LoadBalancing.pool_size, host)
          @online = true
          @last_checked_at = Time.zone.now

          interval = LoadBalancing.replica_check_interval
          @intervals = (interval..(interval * 2)).step(0.5).to_a
        end

        def offline!
          LoadBalancing.log(:warn, "Marking host #{@host} as offline")

          @online = false
          @pool.disconnect!
        end

        # Returns true if the host is online.
        def online?
          return @online unless check_replica_status?

          refresh_status

          LoadBalancing.log(:info, "Host #{@host} came back online") if @online

          @online
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
            SELECT #{Gitlab::Database.pg_wal_lsn_diff}(#{location}, #{Gitlab::Database.pg_last_wal_replay_lsn}())::float
              AS diff
          SQL

          row['diff'].to_i if row.any?
        end

        def primary_write_location
          load_balancer.primary_write_location
        ensure
          load_balancer.release_primary_connection
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
              OR #{Gitlab::Database.pg_wal_lsn_diff}(#{Gitlab::Database.pg_last_wal_replay_lsn}(), #{string}) >= 0
              AS result
          SQL

          row = query_and_release(query)

          row['result'] == 't'
        end

        def query_and_release(sql)
          connection.select_all(sql).first || {}
        rescue
          {}
        ensure
          release_connection
        end
      end
    end
  end
end
