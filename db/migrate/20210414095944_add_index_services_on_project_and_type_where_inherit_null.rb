# frozen_string_literal: true

class AddIndexServicesOnProjectAndTypeWhereInheritNull < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_services_on_project_and_type_where_inherit_null'

  def up
    add_concurrent_index(:services, [:project_id, :type], where: 'inherit_from_id IS NULL', name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:services, INDEX_NAME)
  end
end
