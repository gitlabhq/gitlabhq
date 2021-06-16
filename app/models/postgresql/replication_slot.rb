# frozen_string_literal: true

module Postgresql
  class ReplicationSlot < ApplicationRecord
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
  end
end
