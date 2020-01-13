# frozen_string_literal: true

class AddFkForInstanceAdministratorsGroup < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :application_settings,
      :namespaces,
      column: :instance_administrators_group_id,
      on_delete: :nullify
    )
  end

  def down
    remove_foreign_key :application_settings, column: :instance_administrators_group_id
  end
end
