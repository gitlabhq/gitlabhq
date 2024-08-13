# frozen_string_literal: true

class ValidateFkAutoCanceledByIdForCiPipelines < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  SOURCE_TABLE_NAME = :ci_pipelines
  COLUMN = :auto_canceled_by_id
  PARTITION_COLUMN = :auto_canceled_by_partition_id
  FK_NAME = :fk_262d4c2d19_p

  def up
    validate_foreign_key(
      SOURCE_TABLE_NAME, [PARTITION_COLUMN, COLUMN],
      name: FK_NAME
    )
  end

  def down
    # no-op
  end
end
