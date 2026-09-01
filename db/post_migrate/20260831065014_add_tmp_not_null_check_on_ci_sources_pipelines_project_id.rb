# frozen_string_literal: true

class AddTmpNotNullCheckOnCiSourcesPipelinesProjectId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '19.4'

  TABLE_NAME = 'ci_sources_pipelines'
  SHARDING_KEY = 'project_id'

  # Mirrors the project_id NOT NULL check onto the bigint column, so the swap
  # only has to exchange the two constraint names.
  def up
    return if skip_bigint_migration?(TABLE_NAME, [SHARDING_KEY])

    add_not_null_constraint(TABLE_NAME, bigint_column, constraint_name: tmp_constraint_name, validate: false)
  end

  def down
    return if skip_bigint_migration?(TABLE_NAME, [SHARDING_KEY])

    remove_not_null_constraint(TABLE_NAME, bigint_column, constraint_name: tmp_constraint_name)
  end

  private

  def bigint_column
    convert_to_bigint_column(SHARDING_KEY)
  end

  def tmp_constraint_name
    "#{check_constraint_name(TABLE_NAME, SHARDING_KEY, 'not_null')}_tmp"
  end
end
