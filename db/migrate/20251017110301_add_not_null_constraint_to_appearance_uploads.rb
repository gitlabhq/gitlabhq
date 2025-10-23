# frozen_string_literal: true

class AddNotNullConstraintToAppearanceUploads < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    # NOTE: this constraint enforces that reference columns remain NULL for cell-local architecture compliance
    add_multi_column_not_null_constraint(
      :appearance_uploads,
      :organization_id, :namespace_id, :project_id,
      limit: 0
    )
  end

  def down
    remove_multi_column_not_null_constraint(:appearance_uploads, :organization_id, :namespace_id, :project_id)
  end
end
