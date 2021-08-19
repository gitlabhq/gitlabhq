# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddWorkItemTypeIdToIssue < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    unless column_exists?(:issues, :work_item_type_id)
      with_lock_retries do
        add_column :issues, :work_item_type_id, :bigint
      end
    end

    add_concurrent_index :issues, :work_item_type_id
    add_concurrent_foreign_key :issues, :work_item_types, column: :work_item_type_id, on_delete: nil
  end

  def down
    if foreign_key_exists?(:issues, :work_item_types)
      remove_foreign_key :issues, column: :work_item_type_id
    end

    with_lock_retries do
      remove_column :issues, :work_item_type_id
    end
  end
end
