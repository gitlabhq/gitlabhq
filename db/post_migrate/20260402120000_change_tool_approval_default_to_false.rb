# frozen_string_literal: true

class ChangeToolApprovalDefaultToFalse < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    change_column_default :application_settings, :tool_approval_for_session_enabled, from: true, to: false
  end

  def down
    change_column_default :application_settings, :tool_approval_for_session_enabled, from: false, to: true
  end
end
