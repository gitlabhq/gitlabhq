# frozen_string_literal: true

class LooseForeignKeys::DeletedRecord < ApplicationRecord
  self.primary_key = :id

  scope :for_table, -> (table) { where(fully_qualified_table_name: table) }
  scope :consume_order, -> { order(:partition, :consume_after, :id) }

  enum status: { pending: 1, processed: 2 }, _prefix: :status

  def self.load_batch_for_table(table, batch_size)
    for_table(table)
      .status_pending
      .consume_order
      .limit(batch_size)
      .to_a
  end

  def self.mark_records_processed(all_records)
    # Run a query for each partition to optimize the row lookup by primary key (partition, id)
    update_count = 0

    all_records.group_by(&:partition).each do |partition, records_within_partition|
      update_count += status_pending
        .where(partition: partition)
        .where(id: records_within_partition.pluck(:id))
        .update_all(status: :processed)
    end

    update_count
  end
end
