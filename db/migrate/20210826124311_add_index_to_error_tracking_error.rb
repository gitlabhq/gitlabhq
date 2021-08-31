# frozen_string_literal: true

class AddIndexToErrorTrackingError < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :error_tracking_errors, [:project_id, :status, :last_seen_at], name: 'index_et_errors_on_project_id_and_status_and_last_seen_at'
    add_concurrent_index :error_tracking_errors, [:project_id, :status, :first_seen_at], name: 'index_et_errors_on_project_id_and_status_and_first_seen_at'
    add_concurrent_index :error_tracking_errors, [:project_id, :status, :events_count], name: 'index_et_errors_on_project_id_and_status_and_events_count'
    add_concurrent_index :error_tracking_errors, [:project_id, :status, :id], name: 'index_et_errors_on_project_id_and_status_and_id'
  end

  def down
    remove_concurrent_index :error_tracking_errors, [:project_id, :status, :last_seen_at], name: 'index_et_errors_on_project_id_and_status_and_last_seen_at'
    remove_concurrent_index :error_tracking_errors, [:project_id, :status, :first_seen_at], name: 'index_et_errors_on_project_id_and_status_and_first_seen_at'
    remove_concurrent_index :error_tracking_errors, [:project_id, :status, :events_count], name: 'index_et_errors_on_project_id_and_status_and_events_count'
    remove_concurrent_index :error_tracking_errors, [:project_id, :status, :id], name: 'index_et_errors_on_project_id_and_status_and_id'
  end
end
