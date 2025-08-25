# frozen_string_literal: true

class PartitionedSentNotification < ApplicationRecord # rubocop:disable Gitlab/NamespacedClass,Gitlab/BoundedContexts -- Temp model to partition table
  extend SuppressCompositePrimaryKeyWarning
  include PartitionedTable

  self.table_name = :p_sent_notifications

  attr_readonly :partition
  attribute :partition, default: nil

  # Add every change in SentNotificationsShared as two models should currently share the same logic
  # while we partition the table.
  include SentNotificationsShared

  # Both procs return false for now until the backfill of the table is complete
  partitioned_by :partition, strategy: :sliding_list,
    next_partition_if: ->(_) do
      false
    end,
    detach_partition_if: ->(_) do
      false
    end

  before_save do
    # attr_readonly still allows setting the column on insert
    # This works because we have config.active_record.partial_inserts = true
    clear_attribute_change(:partition)
  end

  def partitioned_reply_key
    return reply_key unless persisted?

    encoded_partition = partition.to_s(INTEGER_CONVERT_BASE)

    "#{encoded_partition}-#{reply_key}"
  end
end
