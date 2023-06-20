# frozen_string_literal: true

class ReplaceVsdIndexWithNullsFirstOrder < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  OLD_INDEX = 'index_on_value_stream_dashboard_aggregations_last_run_at_id'
  NEW_INDEX = 'index_on_value_stream_dashboard_aggregations_last_run_at_and_id'

  def up
    add_concurrent_index :value_stream_dashboard_aggregations,
      [:last_run_at, :namespace_id],
      where: 'enabled IS TRUE',
      name: NEW_INDEX,
      order: { last_run_at: 'ASC NULLS FIRST' }
    remove_concurrent_index_by_name :value_stream_dashboard_aggregations, OLD_INDEX
  end

  def down
    add_concurrent_index :value_stream_dashboard_aggregations,
      [:last_run_at, :namespace_id],
      where: 'enabled IS TRUE',
      name: OLD_INDEX
    remove_concurrent_index_by_name :value_stream_dashboard_aggregations, NEW_INDEX
  end
end
