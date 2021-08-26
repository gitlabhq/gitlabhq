# frozen_string_literal: true

class AddFileTemplateProjectForeignKeyToServiceDeskSettings < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_service_desk_settings_on_file_template_project_id'

  def up
    add_concurrent_index :service_desk_settings, :file_template_project_id, name: INDEX_NAME
    add_concurrent_foreign_key :service_desk_settings, :projects, column: :file_template_project_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :service_desk_settings, column: :file_template_project_id
    end

    remove_concurrent_index_by_name :service_desk_settings, name: INDEX_NAME
  end
end
