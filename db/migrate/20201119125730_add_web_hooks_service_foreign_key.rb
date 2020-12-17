# frozen_string_literal: true

class AddWebHooksServiceForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_web_hooks_on_service_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :web_hooks, :service_id, name: INDEX_NAME
    add_concurrent_foreign_key :web_hooks, :services, column: :service_id, on_delete: :cascade, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :web_hooks, column: :service_id
    end

    remove_concurrent_index_by_name :web_hooks, INDEX_NAME
  end
end
