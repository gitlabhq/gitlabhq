# frozen_string_literal: true

class IndexIssueEmailParticipantsOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_issue_email_participants_on_namespace_id'

  def up
    add_concurrent_index :issue_email_participants, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issue_email_participants, INDEX_NAME
  end
end
