# frozen_string_literal: true

class AddToolApprovalForSessionEnabledToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :project_settings, :tool_approval_for_session_enabled, :boolean
  end
end
