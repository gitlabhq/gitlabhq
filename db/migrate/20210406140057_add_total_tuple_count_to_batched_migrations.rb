# frozen_string_literal: true

class AddTotalTupleCountToBatchedMigrations < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column :batched_background_migrations, :total_tuple_count, :bigint
  end

  def down
    remove_column :batched_background_migrations, :total_tuple_count
  end
end
