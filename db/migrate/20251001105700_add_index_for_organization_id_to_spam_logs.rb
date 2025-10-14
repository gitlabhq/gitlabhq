# frozen_string_literal: true

class AddIndexForOrganizationIdToSpamLogs < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  TABLE_NAME = :spam_logs
  INDEX_NAME = 'index_spam_logs_on_organization_id'

  def up
    add_concurrent_index TABLE_NAME, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
