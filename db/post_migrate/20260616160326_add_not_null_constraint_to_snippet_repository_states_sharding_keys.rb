# frozen_string_literal: true

class AddNotNullConstraintToSnippetRepositoryStatesShardingKeys < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  def up
    add_multi_column_not_null_constraint(:snippet_repository_states, :snippet_project_id, :snippet_organization_id)
  end

  def down
    remove_multi_column_not_null_constraint(:snippet_repository_states, :snippet_project_id, :snippet_organization_id)
  end
end
