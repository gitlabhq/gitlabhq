# frozen_string_literal: true

class GroupProtectedEnvironmentsAddIndexAndConstraint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_protected_environments_on_group_id_and_name'

  disable_ddl_transaction!

  def up
    add_concurrent_index :protected_environments, [:group_id, :name], unique: true,
      name: INDEX_NAME, where: 'group_id IS NOT NULL'
    add_concurrent_foreign_key :protected_environments, :namespaces, column: :group_id, on_delete: :cascade

    add_check_constraint :protected_environments,
      "((project_id IS NULL) != (group_id IS NULL))",
      :protected_environments_project_or_group_existence
  end

  def down
    remove_group_protected_environments!

    remove_check_constraint :protected_environments, :protected_environments_project_or_group_existence
    remove_foreign_key_if_exists :protected_environments, column: :group_id
    remove_concurrent_index_by_name :protected_environments, name: INDEX_NAME
  end

  private

  def remove_group_protected_environments!
    execute <<-SQL
      DELETE FROM protected_environments WHERE group_id IS NOT NULL
    SQL
  end
end
