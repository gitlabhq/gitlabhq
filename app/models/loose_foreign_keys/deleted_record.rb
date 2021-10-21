# frozen_string_literal: true

class LooseForeignKeys::DeletedRecord < ApplicationRecord
  self.primary_key = :id

  scope :for_table, -> (table) { where(fully_qualified_table_name: table) }
  scope :ordered_by_id, -> { order(:id, :primary_key_value) }
  # This needs to be parameterized once we start adding partitions
  scope :for_partition, -> { where(partition: 1) }

  enum status: { pending: 1, processed: 2 }, _prefix: :status

  def self.load_batch_for_table(table, batch_size)
    for_table(table)
      .for_partition
      .status_pending
      .ordered_by_id
      .limit(batch_size)
      .to_a
  end

  def self.mark_records_processed_for_table_between(table, from_record, to_record)
    from = from_record.id
    to = to_record.id

    for_table(table)
      .for_partition
      .status_pending
      .where(id: from..to)
      .update_all(status: :processed)
  end
end
