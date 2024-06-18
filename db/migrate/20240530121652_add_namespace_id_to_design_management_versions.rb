# frozen_string_literal: true

class AddNamespaceIdToDesignManagementVersions < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :design_management_versions, :namespace_id, :bigint
  end
end
