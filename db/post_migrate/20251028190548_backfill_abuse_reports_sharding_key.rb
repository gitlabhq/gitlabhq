# frozen_string_literal: true

class BackfillAbuseReportsShardingKey < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '18.6'

  # To keep transactions as short as possible,
  # see https://docs.gitlab.com/development/migration_style_guide/#heavy-operations-in-a-single-transaction
  disable_ddl_transaction!

  def up
    define_batchable_model(:abuse_reports).each_batch(of: 500) do |batch|
      # NOTE: I want to trigger trigger_f7464057d53e() for all rows
      #       where the sharding key is NULL.
      batch
        .where(organization_id: nil)
        .update_all('updated_at = updated_at')
    end
  end

  def down; end
end
