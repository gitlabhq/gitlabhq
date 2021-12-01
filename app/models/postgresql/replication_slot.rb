# frozen_string_literal: true

module Postgresql
  class ReplicationSlot < Gitlab::Database::SharedModel
    self.table_name = 'pg_replication_slots'

    # Returns true if there are any replication slots in use.
    # PostgreSQL-compatible databases such as Aurora don't support
    # replication slots, so this will return false as well.
    def self.in_use?
      transaction { exists? }
    rescue ActiveRecord::StatementInvalid
      false
    end

    # Returns true if the lag observed across all replication slots exceeds a
    # given threshold.
    #
    # max - The maximum replication lag size, in bytes. Based on GitLab.com
    #       statistics it takes between 1 and 5 seconds to replicate around
    #       100 MB of data.
    def self.lag_too_great?(max = 100.megabytes)
      return false unless in_use?

      lag_function = "pg_wal_lsn_diff" \
        "(pg_current_wal_insert_lsn(), restart_lsn)::bigint"

      # We force the use of a transaction here so the query always goes to the
      # primary, even when using the DB load balancer.
      sizes = transaction { pluck(Arel.sql(lag_function)) }
      too_great = sizes.compact.count { |size| size >= max }

      # If too many replicas are falling behind too much, the availability of a
      # GitLab instance might suffer. To prevent this from happening we require
      # at least 1 replica to have data recent enough.
      if sizes.any? && too_great > 0
        (sizes.length - too_great) <= 1
      else
        false
      end
    end

    def self.count
      connection
        .execute("SELECT COUNT(*) FROM pg_replication_slots;")
        .first
        .fetch('count')
        .to_i
    end

    def self.unused_slots_count
      connection
        .execute("SELECT COUNT(*) FROM pg_replication_slots WHERE active = 'f';")
        .first
        .fetch('count')
        .to_i
    end

    def self.used_slots_count
      connection
        .execute("SELECT COUNT(*) FROM pg_replication_slots WHERE active = 't';")
        .first
        .fetch('count')
        .to_i
    end

    # array of slots and the retained_bytes
    # https://www.skillslogic.com/blog/databases/checking-postgres-replication-lag
    # http://bdr-project.org/docs/stable/monitoring-peers.html
    def self.slots_retained_bytes
      connection.execute(<<-SQL.squish).to_a
        SELECT slot_name, database,
              active, pg_wal_lsn_diff(pg_current_wal_insert_lsn(), restart_lsn)
          AS retained_bytes
          FROM pg_replication_slots;
      SQL
    end

    # returns the max number WAL space (in bytes) being used across the replication slots
    def self.max_retained_wal
      connection.execute(<<-SQL.squish).first.fetch('coalesce').to_i
        SELECT COALESCE(MAX(pg_wal_lsn_diff(pg_current_wal_insert_lsn(), restart_lsn)), 0)
          FROM pg_replication_slots;
      SQL
    end

    def self.max_replication_slots
      connection.execute(<<-SQL.squish).first&.fetch('setting').to_i
        SELECT setting FROM pg_settings WHERE name = 'max_replication_slots';
      SQL
    end
  end
end
