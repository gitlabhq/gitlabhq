# frozen_string_literal: true

class RemoveProjectsCiResourceGroupsProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_resource_groups, :projects, name: "fk_774722d144")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_resource_groups, :projects, name: "fk_774722d144", column: :project_id, target_column: :id, on_delete: "cascade")
  end
end
