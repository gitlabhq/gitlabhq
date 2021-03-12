# frozen_string_literal: true

class RemoveIndexOnIssuesWhereServiceDeskReplyToIsNotNull < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_TABLE = :issues
  INDEX_NAME = 'idx_on_issues_where_service_desk_reply_to_is_not_null'

  def up
    Gitlab::BackgroundMigration.steal('PopulateIssueEmailParticipants')
    remove_concurrent_index_by_name INDEX_TABLE, INDEX_NAME
  end

  def down
    add_concurrent_index(INDEX_TABLE, [:id], name: INDEX_NAME, where: 'service_desk_reply_to IS NOT NULL')
  end
end
