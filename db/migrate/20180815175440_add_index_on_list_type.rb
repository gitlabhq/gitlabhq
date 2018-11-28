# frozen_string_literal: true
class AddIndexOnListType < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :lists, :list_type
  end

  def down
    remove_concurrent_index :lists, :list_type
  end
end
