# frozen_string_literal: true

class PrepareVocPartitionIdNotNullValidation < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  TABLE_NAME = :vulnerability_occurrences
  CONSTRAINT_NAME = 'check_3225d02bda'

  def up
    prepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end
end
