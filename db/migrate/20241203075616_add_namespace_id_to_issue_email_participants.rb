# frozen_string_literal: true

class AddNamespaceIdToIssueEmailParticipants < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :issue_email_participants, :namespace_id, :bigint
  end
end
