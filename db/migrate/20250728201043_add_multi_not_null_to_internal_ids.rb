# frozen_string_literal: true

class AddMultiNotNullToInternalIds < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_multi_column_not_null_constraint(:internal_ids, :namespace_id, :project_id, validate: false)
  end

  def down
    remove_multi_column_not_null_constraint(:internal_ids, :namespace_id, :project_id)
  end
end
