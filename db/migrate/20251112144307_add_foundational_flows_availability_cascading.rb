# frozen_string_literal: true

class AddFoundationalFlowsAvailabilityCascading < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  disable_ddl_transaction!

  milestone '18.7'

  def up
    add_cascading_namespace_setting :duo_foundational_flows_enabled, :boolean,
      default: false, null: false
  end

  def down
    remove_cascading_namespace_setting :duo_foundational_flows_enabled
  end
end
