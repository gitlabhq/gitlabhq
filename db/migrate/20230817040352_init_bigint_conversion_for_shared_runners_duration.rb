# frozen_string_literal: true

class InitBigintConversionForSharedRunnersDuration < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAMES = %i[ci_project_monthly_usages ci_namespace_monthly_usages]
  COLUMN_NAMES = %i[shared_runners_duration]

  def up
    TABLE_NAMES.each do |table_name|
      initialize_conversion_of_integer_to_bigint table_name, COLUMN_NAMES
    end
  end

  def down
    TABLE_NAMES.each do |table_name|
      revert_initialize_conversion_of_integer_to_bigint table_name, COLUMN_NAMES
    end
  end
end
