# frozen_string_literal: true

class ChangeServicesInheritFromIdForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :services, :services, column: :inherit_from_id, on_delete: :cascade, name: 'fk_services_inherit_from_id'
    remove_foreign_key_if_exists :services, name: 'fk_868a8e7ad6'
  end

  def down
    remove_foreign_key_if_exists :services, name: 'fk_services_inherit_from_id'
    add_concurrent_foreign_key :services, :services, column: :inherit_from_id, on_delete: :nullify, name: 'fk_868a8e7ad6'
  end
end
