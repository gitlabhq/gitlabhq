# frozen_string_literal: true

class AddIndexOnEnvironmentsWithState < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :environments, [:project_id, :state]
  end

  def down
    remove_concurrent_index :environments, [:project_id, :state]
  end
end
