class AddProjectIdToSubscriptions < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :subscriptions, :project_id, :integer
    add_foreign_key :subscriptions, :projects, column: :project_id, on_delete: :cascade # rubocop: disable Migration/AddConcurrentForeignKey
  end

  def down
    remove_foreign_key :subscriptions, column: :project_id
    remove_column :subscriptions, :project_id
  end
end
