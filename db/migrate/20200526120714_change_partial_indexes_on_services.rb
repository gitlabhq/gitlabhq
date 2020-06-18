# frozen_string_literal: true

class ChangePartialIndexesOnServices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :services, [:type, :instance], unique: true, where: 'instance = true', name: 'index_services_on_type_and_instance_partial'
    remove_concurrent_index_by_name :services, 'index_services_on_type_and_instance'

    add_concurrent_index :services, [:type, :template], unique: true, where: 'template = true', name: 'index_services_on_type_and_template_partial'
    remove_concurrent_index_by_name :services, 'index_services_on_type_and_template'
  end

  def down
    add_concurrent_index :services, [:type, :instance], unique: true, where: 'instance IS TRUE', name: 'index_services_on_type_and_instance'
    remove_concurrent_index_by_name :services, 'index_services_on_type_and_instance_partial'

    add_concurrent_index :services, [:type, :template], unique: true, where: 'template IS TRUE', name: 'index_services_on_type_and_template'
    remove_concurrent_index_by_name :services, 'index_services_on_type_and_template_partial'
  end
end
