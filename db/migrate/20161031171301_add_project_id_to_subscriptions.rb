class AddProjectIdToSubscriptions < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :subscriptions, :project_id, :integer
    add_foreign_key :subscriptions, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    remove_column :subscriptions, :project_id
  end
end
