# frozen_string_literal: true

class BackfillAbuseEventsOrganizationId < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!
  milestone '18.6'

  def up
    define_batchable_model(:abuse_events).each_batch(of: 500) do |batch|
      # Trigger trigger_ca93521f3a6d() to backfill organization_id
      batch
        .where(organization_id: nil)
        .update_all('updated_at = updated_at')
    end
  end

  def down; end
end
