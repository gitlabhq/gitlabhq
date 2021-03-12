# frozen_string_literal: true

class RecreateIndexIssueEmailParticipantsOnIssueIdAndEmail < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_issue_email_participants_on_issue_id_and_email'
  NEW_INDEX_NAME = 'index_issue_email_participants_on_issue_id_and_lower_email'

  def up
    # This table is currently empty, so no need to worry about unique index violations
    add_concurrent_index :issue_email_participants, 'issue_id, lower(email)', unique: true, name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :issue_email_participants, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :issue_email_participants, [:issue_id, :email], unique: true, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :issue_email_participants, NEW_INDEX_NAME
  end
end
