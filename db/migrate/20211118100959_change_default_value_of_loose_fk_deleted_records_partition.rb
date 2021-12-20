# frozen_string_literal: true

class ChangeDefaultValueOfLooseFkDeletedRecordsPartition < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    change_column_default(:loose_foreign_keys_deleted_records, :partition, from: nil, to: 1)
  end
end
