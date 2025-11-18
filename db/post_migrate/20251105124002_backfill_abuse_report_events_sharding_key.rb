# frozen_string_literal: true

class BackfillAbuseReportEventsShardingKey < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '18.6'

  # To keep transactions as short as possible,
  # see https://docs.gitlab.com/development/migration_style_guide/#heavy-operations-in-a-single-transaction
  disable_ddl_transaction!

  def up
    define_batchable_model(:abuse_report_events).each_batch(of: 100) do |batch|
      # NOTE: This will trigger trigger_1996c9e5bea0() for all rows
      #       where the sharding key is NULL.
      batch
        .where(organization_id: nil)
        .update_all('created_at = created_at')
    end
  end

  def down; end
end
