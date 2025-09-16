# frozen_string_literal: true

class AddDuoRemoteFlowsEnabledCascadingSetting < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  def up
    add_cascading_namespace_setting :duo_remote_flows_enabled, :boolean, default: true, null: false
  end

  def down
    remove_cascading_namespace_setting :duo_remote_flows_enabled
  end
end
