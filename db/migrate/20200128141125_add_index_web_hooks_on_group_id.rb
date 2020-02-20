# frozen_string_literal: true

class AddIndexWebHooksOnGroupId < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :web_hooks, :group_id, where: "type = 'GroupHook'"
  end

  def down
    remove_concurrent_index :web_hooks, :group_id, where: "type = 'GroupHook'"
  end
end
