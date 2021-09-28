# frozen_string_literal: true

class ImproveIndexForErrorTracking < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_index :error_tracking_errors, %i(project_id status last_seen_at id),
      order: { last_seen_at: :desc, id: :desc },
      name: 'index_et_errors_on_project_id_and_status_last_seen_at_id_desc'

    add_concurrent_index :error_tracking_errors, %i(project_id status first_seen_at id),
      order: { first_seen_at: :desc, id: :desc },
      name: 'index_et_errors_on_project_id_and_status_first_seen_at_id_desc'

    add_concurrent_index :error_tracking_errors, %i(project_id status events_count id),
      order: { events_count: :desc, id: :desc },
      name: 'index_et_errors_on_project_id_and_status_events_count_id_desc'

    remove_concurrent_index :error_tracking_errors, [:project_id, :status, :last_seen_at], name: 'index_et_errors_on_project_id_and_status_and_last_seen_at'
    remove_concurrent_index :error_tracking_errors, [:project_id, :status, :first_seen_at], name: 'index_et_errors_on_project_id_and_status_and_first_seen_at'
    remove_concurrent_index :error_tracking_errors, [:project_id, :status, :events_count], name: 'index_et_errors_on_project_id_and_status_and_events_count'
  end

  def down
    add_concurrent_index :error_tracking_errors, [:project_id, :status, :last_seen_at], name: 'index_et_errors_on_project_id_and_status_and_last_seen_at'
    add_concurrent_index :error_tracking_errors, [:project_id, :status, :first_seen_at], name: 'index_et_errors_on_project_id_and_status_and_first_seen_at'
    add_concurrent_index :error_tracking_errors, [:project_id, :status, :events_count], name: 'index_et_errors_on_project_id_and_status_and_events_count'

    remove_concurrent_index :error_tracking_errors, [:project_id, :status, :last_seen_at, :id], name: 'index_et_errors_on_project_id_and_status_last_seen_at_id_desc'
    remove_concurrent_index :error_tracking_errors, [:project_id, :status, :first_seen_at, :id], name: 'index_et_errors_on_project_id_and_status_first_seen_at_id_desc'
    remove_concurrent_index :error_tracking_errors, [:project_id, :status, :events_count, :id], name: 'index_et_errors_on_project_id_and_status_events_count_id_desc'
  end
end
