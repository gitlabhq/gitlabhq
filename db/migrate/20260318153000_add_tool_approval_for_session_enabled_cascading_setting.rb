# frozen_string_literal: true

class AddToolApprovalForSessionEnabledCascadingSetting < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  def up
    add_cascading_namespace_setting :tool_approval_for_session_enabled, :boolean, default: true, null: false
  end

  def down
    remove_cascading_namespace_setting :tool_approval_for_session_enabled
  end
end
