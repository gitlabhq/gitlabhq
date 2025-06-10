# frozen_string_literal: true

class DropWorkspacesActualStateUpdatedAtDefault < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    change_column_default :workspaces, :actual_state_updated_at, from: '1970-01-01', to: nil
  end
end
