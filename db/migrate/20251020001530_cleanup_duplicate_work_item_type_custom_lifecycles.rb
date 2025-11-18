# frozen_string_literal: true

class CleanupDuplicateWorkItemTypeCustomLifecycles < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # Remove duplicate records, keeping only the most recent one for each (namespace_id, work_item_type_id) pair
    execute <<~SQL
      DELETE FROM work_item_type_custom_lifecycles
      WHERE id NOT IN (
        SELECT DISTINCT ON (namespace_id, work_item_type_id) id
        FROM work_item_type_custom_lifecycles
        ORDER BY namespace_id, work_item_type_id, id DESC
      )
    SQL
  end

  def down
    # This is irreversible - we can't restore deleted duplicate records
    # The down migration is intentionally left empty
  end
end
