# frozen_string_literal: true

class AddIndexForInstanceAdministratorsGroup < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :application_settings, :instance_administrators_group_id
  end

  def down
    remove_concurrent_index :application_settings, :instance_administrators_group_id
  end
end
