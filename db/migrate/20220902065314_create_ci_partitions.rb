# frozen_string_literal: true

class CreateCiPartitions < Gitlab::Database::Migration[2.0]
  def change
    create_table :ci_partitions do |t|
      t.timestamps_with_timezone null: false
    end
  end
end
