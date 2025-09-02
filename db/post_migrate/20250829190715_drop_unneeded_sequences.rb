# frozen_string_literal: true

class DropUnneededSequences < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    drop_sequence(:project_incident_management_settings, :project_id,
      :project_incident_management_settings_project_id_seq)
    drop_sequence(:user_statuses, :user_id, :user_statuses_user_id_seq)
  end

  # NOP because these sequences were never used, and re-adding them
  # causes the columns to be altered to use them as default values.
  def down; end
end
