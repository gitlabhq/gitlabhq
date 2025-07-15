# frozen_string_literal: true

class AddMultiColumnNotNullConstraintToSnippetRepositoryStorageMoves < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:snippet_repository_storage_moves, :snippet_project_id,
      :snippet_organization_id)
  end

  def down
    remove_multi_column_not_null_constraint(:snippet_repository_storage_moves, :snippet_project_id,
      :snippet_organization_id)
  end
end
