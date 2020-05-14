# frozen_string_literal: true

class AddIndexInheritFromIdToServices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :services, :inherit_from_id

    add_concurrent_foreign_key :services, :services, column: :inherit_from_id, on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists :services, column: :inherit_from_id

    remove_concurrent_index :services, :inherit_from_id
  end
end
