# frozen_string_literal: true

class AddNamespaceForeignKeyToCiPendingBuild < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!
  INDEX_NAME = 'index_ci_pending_builds_on_namespace_id'

  def up
    add_concurrent_index(:ci_pending_builds, :namespace_id, name: INDEX_NAME)
    add_concurrent_foreign_key(:ci_pending_builds, :namespaces, column: :namespace_id, on_delete: :cascade)
  end

  def down
    remove_foreign_key_if_exists(:ci_pending_builds, column: :namespace_id)
    remove_concurrent_index_by_name(:ci_pending_builds, INDEX_NAME)
  end
end
