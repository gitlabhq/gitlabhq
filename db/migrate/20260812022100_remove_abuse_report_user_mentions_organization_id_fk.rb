# frozen_string_literal: true

class RemoveAbuseReportUserMentionsOrganizationIdFk < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :abuse_report_user_mentions, :organizations, column: :organization_id
    end
  end

  def down
    add_concurrent_foreign_key :abuse_report_user_mentions, :organizations, column: :organization_id,
      on_delete: :cascade, name: 'fk_f4c2b15ef9'
  end
end
