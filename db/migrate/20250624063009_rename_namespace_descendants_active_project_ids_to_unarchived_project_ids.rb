# frozen_string_literal: true

class RenameNamespaceDescendantsActiveProjectIdsToUnarchivedProjectIds < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  def up
    rename_column_concurrently :namespace_descendants, :all_active_project_ids,
      :all_unarchived_project_ids, type: 'bigint[]', batch_column_name: :namespace_id
  end

  def down
    undo_rename_column_concurrently :namespace_descendants, :all_active_project_ids,
      :all_unarchived_project_ids
  end
end
