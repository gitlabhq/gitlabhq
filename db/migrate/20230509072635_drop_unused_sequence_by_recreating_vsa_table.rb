# frozen_string_literal: true

class DropUnusedSequenceByRecreatingVsaTable < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    # dropping is OK since we re-add the table in the same transaction
    drop_table :value_stream_dashboard_aggregations, if_exists: true # rubocop: disable Migration/DropTable
    create_table :value_stream_dashboard_aggregations, id: false do |t|
      # Note: default: nil will prevent SEQUENCE creation
      t.references :namespace, primary_key: true, null: false, index: false, foreign_key: { on_delete: :cascade },
        default: nil
      t.datetime_with_timezone :last_run_at
      t.boolean :enabled, null: false, default: true

      t.index [:last_run_at, :namespace_id], where: 'enabled IS TRUE',
        name: 'index_on_value_stream_dashboard_aggregations_last_run_at_id'
    end
  end

  def down
    # no-op, we don't want to restore the sequence
  end
end
