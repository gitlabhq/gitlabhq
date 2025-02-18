# frozen_string_literal: true

class AddNamespaceIdToDesignManagementDesignsVersions < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :design_management_designs_versions, :namespace_id, :bigint
  end
end
