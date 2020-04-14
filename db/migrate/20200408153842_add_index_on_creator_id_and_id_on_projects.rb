# frozen_string_literal: true

class AddIndexOnCreatorIdAndIdOnProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:creator_id, :id]
  end

  def down
    remove_concurrent_index :projects, [:creator_id, :id]
  end
end
