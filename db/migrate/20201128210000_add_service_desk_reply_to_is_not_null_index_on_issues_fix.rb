# frozen_string_literal: true

class AddServiceDeskReplyToIsNotNullIndexOnIssuesFix < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'idx_on_issues_where_service_desk_reply_to_is_not_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:issues, [:id], name: INDEX_NAME, where: 'service_desk_reply_to IS NOT NULL')
  end

  def down
    remove_concurrent_index_by_name(:issues, INDEX_NAME)
  end
end
