# frozen_string_literal: true

class RemovingForeignKeyOauthAccessGrantArchivedRecords < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.8'

  TABLE_NAME = :oauth_access_grant_archived_records

  def up
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :organizations, column: :organization_id
    end
  end

  def down
    # Foreign key will be recreated by the table creation migration's rollback
  end
end
