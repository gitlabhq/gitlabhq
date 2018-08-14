# frozen_string_literal: true

module Postgresql
  class ReplicationSlot < ActiveRecord::Base
    self.table_name = 'pg_replication_slots'

    # Returns true if the lag observed across all replication slots exceeds a
    # given threshold.
    #
    # max - The maximum replication lag size, in bytes. Based on GitLab.com
    #       statistics it takes between 1 and 5 seconds to replicate around
    #       100 MB of data.
    def self.lag_too_great?(max = 100.megabytes)
      lag_function = "#{Gitlab::Database.pg_wal_lsn_diff}" \
        "(#{Gitlab::Database.pg_current_wal_insert_lsn}(), restart_lsn)::bigint"

      # We force the use of a transaction here so the query always goes to the
      # primary, even when using the EE DB load balancer.
      sizes = transaction { pluck(lag_function) }
      too_great = sizes.count { |size| size >= max }

      # If too many replicas are falling behind too much, the availability of a
      # GitLab instance might suffer. To prevent this from happening we require
      # at least 1 replica to have data recent enough.
      if sizes.any? && too_great.positive?
        (sizes.length - too_great) <= 1
      else
        false
      end
    end
  end
end
