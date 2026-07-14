# frozen_string_literal: true

class PrepareVoiPartitionIdNotNullValidation < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  TABLE_NAME = :vulnerability_occurrence_identifiers
  CONSTRAINT_NAME = 'check_aacd1ff57e'

  def up
    prepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end
end
