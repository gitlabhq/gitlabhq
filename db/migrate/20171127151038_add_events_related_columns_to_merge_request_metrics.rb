class AddEventsRelatedColumnsToMergeRequestMetrics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    change_table :merge_request_metrics do |t|
      t.references :merged_by, references: :users
      t.references :latest_closed_by, references: :users
    end

    add_column :merge_request_metrics, :latest_closed_at, :datetime_with_timezone

    add_concurrent_foreign_key :merge_request_metrics, :users,
                               column: :merged_by_id,
                               on_delete: :nullify

    add_concurrent_foreign_key :merge_request_metrics, :users,
                               column: :latest_closed_by_id,
                               on_delete: :nullify
  end

  def down
    if foreign_keys_for(:merge_request_metrics, :merged_by_id).any?
      remove_foreign_key :merge_request_metrics, column: :merged_by_id
    end

    if foreign_keys_for(:merge_request_metrics, :latest_closed_by_id).any?
      remove_foreign_key :merge_request_metrics, column: :latest_closed_by_id
    end

    remove_columns :merge_request_metrics,
      :merged_by_id, :latest_closed_by_id, :latest_closed_at
  end
end
