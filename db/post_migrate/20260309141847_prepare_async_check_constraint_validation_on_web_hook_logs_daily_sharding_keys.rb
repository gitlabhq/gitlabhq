# frozen_string_literal: true

class PrepareAsyncCheckConstraintValidationOnWebHookLogsDailyShardingKeys < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  PARTITIONED_TABLE_NAME = :web_hook_logs_daily
  CONSTRAINT_NAME = 'check_19dc80d658'

  def up
    prepare_partitioned_async_check_constraint_validation PARTITIONED_TABLE_NAME, name: CONSTRAINT_NAME
  end

  def down
    unprepare_partitioned_async_check_constraint_validation PARTITIONED_TABLE_NAME, name: CONSTRAINT_NAME
  end
end
