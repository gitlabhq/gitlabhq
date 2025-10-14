# frozen_string_literal: true

class FinalizeHkFixStringConfigHashesInstanceStreamingDestinations < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'FixStringConfigHashesInstanceStreamingDestinations',
      table_name: :audit_events_instance_external_streaming_destinations,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
