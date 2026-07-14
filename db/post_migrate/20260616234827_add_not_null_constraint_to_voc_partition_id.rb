# frozen_string_literal: true

class AddNotNullConstraintToVocPartitionId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  TABLE_NAME = :vulnerability_occurrences
  COLUMN_NAME = :partition_id

  def up
    add_not_null_constraint TABLE_NAME, COLUMN_NAME, validate: false
  end

  def down
    remove_not_null_constraint TABLE_NAME, COLUMN_NAME
  end
end
