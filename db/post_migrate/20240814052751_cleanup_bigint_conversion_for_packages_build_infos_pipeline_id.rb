# frozen_string_literal: true

class CleanupBigintConversionForPackagesBuildInfosPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  enable_lock_retries!

  TABLE = :packages_build_infos
  COLUMNS = [:pipeline_id]

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
