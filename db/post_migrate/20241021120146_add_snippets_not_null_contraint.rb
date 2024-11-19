# frozen_string_literal: true

class AddSnippetsNotNullContraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  def up
    add_multi_column_not_null_constraint(:snippets, :project_id, :organization_id)
  end

  def down
    remove_multi_column_not_null_constraint(:snippets, :project_id, :organization_id)
  end
end
