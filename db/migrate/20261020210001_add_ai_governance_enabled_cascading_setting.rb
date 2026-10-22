# frozen_string_literal: true

class AddAiGovernanceEnabledCascadingSetting < Gitlab::Database::Migration[2.4]
  milestone '19.6'
  disable_ddl_transaction!

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  def up
    add_cascading_namespace_setting :ai_governance_enabled, :boolean, default: false, null: false
  end

  def down
    remove_cascading_namespace_setting :ai_governance_enabled
  end
end
