# frozen_string_literal: true

class AddActualStateUpdatedAtToWorkspaces < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :workspaces, :actual_state_updated_at, :datetime_with_timezone, null: false, default: '1970-01-01'
  end
end
