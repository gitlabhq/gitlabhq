# frozen_string_literal: true

class AddIsRemovedToOncallParticipant < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :incident_management_oncall_participants, :is_removed, :boolean, default: false, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :incident_management_oncall_participants, :is_removed
    end
  end
end
