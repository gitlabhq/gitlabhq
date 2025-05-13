# frozen_string_literal: true

class AddIssueEmailParticipantsNamespaceIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.0'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :issue_email_participants, :namespace_id
  end

  def down
    remove_not_null_constraint :issue_email_participants, :namespace_id
  end
end
