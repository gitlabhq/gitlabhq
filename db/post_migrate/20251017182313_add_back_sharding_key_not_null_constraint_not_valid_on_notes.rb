# frozen_string_literal: true

class AddBackShardingKeyNotNullConstraintNotValidOnNotes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_multi_column_not_null_constraint :notes,
      :project_id,
      :namespace_id,
      :organization_id,
      operator: '>=',
      validate: false
  end

  def down
    remove_multi_column_not_null_constraint :notes, :project_id, :namespace_id, :organization_id
  end
end
