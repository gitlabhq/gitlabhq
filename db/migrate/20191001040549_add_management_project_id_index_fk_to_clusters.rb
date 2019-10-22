# frozen_string_literal: true

class AddManagementProjectIdIndexFkToClusters < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :clusters, :projects, column: :management_project_id, on_delete: :nullify
    add_concurrent_index :clusters, :management_project_id, where: 'management_project_id IS NOT NULL'
  end

  def down
    remove_concurrent_index :clusters, :management_project_id
    remove_foreign_key_if_exists :clusters, column: :management_project_id
  end
end
