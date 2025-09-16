# frozen_string_literal: true

class FinalizeAuditEventDestinationMigrations < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'FixIncompleteExternalAuditDestinations',
      table_name: :audit_events_external_audit_event_destinations,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )

    ensure_batched_background_migration_is_finished(
      job_class_name: 'FixIncompleteInstanceExternalAuditDestinations',
      table_name: :audit_events_instance_external_audit_event_destinations,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )

    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillGoogleGroupAuditEventDestinationsFixed',
      table_name: :audit_events_google_cloud_logging_configurations,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )

    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillGoogleInstanceAuditEventDestinationsFixed',
      table_name: :audit_events_instance_google_cloud_logging_configurations,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )

    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillAmazonGroupAuditEventDestinationsFixed',
      table_name: :audit_events_amazon_s3_configurations,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )

    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillAmazonInstanceAuditEventDestinationsFixed',
      table_name: :audit_events_instance_amazon_s3_configurations,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )

    ensure_batched_background_migration_is_finished(
      job_class_name: 'FixSecretTokensForHttpDestinations',
      table_name: :audit_events_group_external_streaming_destinations,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
