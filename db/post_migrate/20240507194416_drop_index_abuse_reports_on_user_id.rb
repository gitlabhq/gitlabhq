# frozen_string_literal: true

class DropIndexAbuseReportsOnUserId < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  TABLE_NAME = :abuse_reports
  INDEX_NAME = :index_abuse_reports_on_user_id
  COLUMN_NAMES = [:user_id]

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end
end
