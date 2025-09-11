# frozen_string_literal: true

class ReAddNotValidNotNullContraintOnIntegrations < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:integrations, :group_id, :project_id, :organization_id, validate: false)
  end

  def down
    remove_multi_column_not_null_constraint(:integrations, :group_id, :project_id, :organization_id)
  end
end
