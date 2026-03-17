# frozen_string_literal: true

class AddAbuseReportUploadStatesOrganizationIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    install_sharding_key_assignment_trigger(
      table: :abuse_report_upload_states,
      sharding_key: :organization_id,
      parent_table: :abuse_report_uploads,
      parent_sharding_key: :organization_id,
      foreign_key: :abuse_report_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :abuse_report_upload_states,
      sharding_key: :organization_id,
      parent_table: :abuse_report_uploads,
      parent_sharding_key: :organization_id,
      foreign_key: :abuse_report_upload_id
    )
  end
end
