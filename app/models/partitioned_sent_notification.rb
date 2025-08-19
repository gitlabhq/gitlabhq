# frozen_string_literal: true

class PartitionedSentNotification < ApplicationRecord # rubocop:disable Gitlab/NamespacedClass,Gitlab/BoundedContexts -- Temp model to partition table
  extend SuppressCompositePrimaryKeyWarning
  include PartitionedTable

  self.table_name = :p_sent_notifications

  attr_readonly :partition

  # Both procs return false for now until the backfill of the table is complete
  partitioned_by :partition, strategy: :sliding_list,
    next_partition_if: ->(_) do
      false
    end,
    detach_partition_if: ->(_) do
      false
    end
end
