class AddRepositoryUpdateEventsToWebHooks < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :web_hooks, :repository_update_events, :boolean, default: false, allow_null: false
  end

  def down
    remove_column :web_hooks, :repository_update_events
  end
end
