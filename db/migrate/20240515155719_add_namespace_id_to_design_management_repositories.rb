# frozen_string_literal: true

class AddNamespaceIdToDesignManagementRepositories < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :design_management_repositories, :namespace_id, :bigint
  end
end
