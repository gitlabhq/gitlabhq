# frozen_string_literal: true

class DropMultiParentConstraintOnNotes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    remove_multi_column_not_null_constraint :notes, :project_id, :namespace_id, :organization_id
  end

  def down
    # no-op
    # We no-op the migration that introduced the constraint in the first place
  end
end
