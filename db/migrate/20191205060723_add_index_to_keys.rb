# frozen_string_literal: true

class AddIndexToKeys < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :keys, :last_used_at, order: { last_used_at: 'DESC NULLS LAST' }
  end

  def down
    remove_concurrent_index :keys, :last_used_at
  end
end
