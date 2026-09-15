# frozen_string_literal: true

class ValidateTmpNotNullCheckOnCiSourcesPipelinesProjectId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '19.4'

  TABLE_NAME = 'ci_sources_pipelines'
  SHARDING_KEY = 'project_id'

  # The check has to be valid before the swap renames it onto project_id,
  # otherwise the sharding key ends up guarded by a NOT VALID constraint.
  def up
    return unless check_not_null_constraint_exists?(TABLE_NAME, bigint_column, constraint_name: tmp_constraint_name)

    validate_not_null_constraint(TABLE_NAME, bigint_column, constraint_name: tmp_constraint_name)
  end

  def down
    # No-op. A validated constraint is dropped by the migration that added it.
  end

  private

  def bigint_column
    convert_to_bigint_column(SHARDING_KEY)
  end

  def tmp_constraint_name
    "#{check_constraint_name(TABLE_NAME, SHARDING_KEY, 'not_null')}_tmp"
  end
end
