# frozen_string_literal: true

class AddUniqueIndexOnPlanName < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :plans, :name
    add_concurrent_index :plans, :name, unique: true
  end

  def down
    remove_concurrent_index :plans, :name, unique: true
    add_concurrent_index :plans, :name
  end
end
