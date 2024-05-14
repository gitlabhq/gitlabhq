# frozen_string_literal: true

class PrepareAsyncTraversalIdsCheckConstraintValidation < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  CONSTRAINT_NAME = 'check_f5ba7c2496'

  def up
    prepare_async_check_constraint_validation :vulnerability_reads, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :vulnerability_reads, name: CONSTRAINT_NAME
  end
end
