# frozen_string_literal: true

class AddStateToMergeTrains < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  MERGE_TRAIN_STATUS_CREATED = 0 # Equivalent to MergeTrain.statuses[:created]
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :merge_trains, :status, :integer, limit: 2, default: MERGE_TRAIN_STATUS_CREATED
  end

  def down
    remove_column :merge_trains, :status
  end
end
