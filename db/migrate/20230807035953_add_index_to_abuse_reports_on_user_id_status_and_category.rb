# frozen_string_literal: true

class AddIndexToAbuseReportsOnUserIdStatusAndCategory < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_abuse_reports_user_id_status_and_category'

  def up
    add_concurrent_index :abuse_reports, [:user_id, :status, :category], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :abuse_reports, INDEX_NAME
  end
end
