# frozen_string_literal: true

class AddIndexOnActiveAndTemplateAndTypeAndIdToServices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_services_on_type_and_id_and_template_when_active'

  disable_ddl_transaction!

  def up
    add_concurrent_index :services, [:type, :id, :template], where: 'active = TRUE', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :services, INDEX_NAME
  end
end
