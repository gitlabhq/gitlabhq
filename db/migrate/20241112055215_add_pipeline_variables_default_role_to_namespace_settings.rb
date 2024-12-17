# frozen_string_literal: true

class AddPipelineVariablesDefaultRoleToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  DEVELOPER_ROLE = 2

  def change
    add_column :namespace_settings, :pipeline_variables_default_role,
      :integer, default: DEVELOPER_ROLE, null: false, limit: 2
  end
end
