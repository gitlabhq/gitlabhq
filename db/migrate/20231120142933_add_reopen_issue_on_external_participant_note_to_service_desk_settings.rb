# frozen_string_literal: true

class AddReopenIssueOnExternalParticipantNoteToServiceDeskSettings < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  enable_lock_retries!

  def change
    add_column :service_desk_settings, :reopen_issue_on_external_participant_note, :boolean, null: false, default: false
  end
end
