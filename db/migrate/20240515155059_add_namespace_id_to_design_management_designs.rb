# frozen_string_literal: true

class AddNamespaceIdToDesignManagementDesigns < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :design_management_designs, :namespace_id, :bigint
  end
end
