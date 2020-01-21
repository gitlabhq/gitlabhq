# frozen_string_literal: true

class AddFkToCiResourceGroupsProjectId < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_resource_groups, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :ci_resource_groups, column: :project_id
  end
end
