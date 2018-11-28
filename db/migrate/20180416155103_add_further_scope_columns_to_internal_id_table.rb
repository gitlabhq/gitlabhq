class AddFurtherScopeColumnsToInternalIdTable < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_null :internal_ids, :project_id, true
    add_column :internal_ids, :namespace_id, :integer, null: true
  end

  def down
    change_column_null :internal_ids, :project_id, false
    remove_column :internal_ids, :namespace_id
  end
end
