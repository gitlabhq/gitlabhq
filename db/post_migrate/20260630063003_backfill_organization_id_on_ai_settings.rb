# frozen_string_literal: true

class BackfillOrganizationIdOnAiSettings < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  DEFAULT_ORG_ID = 1

  def up
    # ai_settings is a singleton table (CHECK check_singleton enforces a single
    # row), so this backfill touches at most one row and does not require
    # each_batch iteration.
    define_batchable_model('ai_settings')
      .where(organization_id: nil)
      .update_all(organization_id: DEFAULT_ORG_ID)
  end

  def down
    # no-op
  end
end
