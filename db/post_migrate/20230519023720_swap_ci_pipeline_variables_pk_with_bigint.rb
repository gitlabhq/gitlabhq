# frozen_string_literal: true

class SwapCiPipelineVariablesPkWithBigint < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  disable_ddl_transaction!

  TABLE_NAME = 'ci_pipeline_variables'

  def up
    swap
  end

  def down
    swap(stepping_down: true)
  end

  private

  def swap(stepping_down: false)
    # Prepare the names we need below
    primary_key_constraint_name = "#{TABLE_NAME}_pkey"
    sequence_name = "#{TABLE_NAME}_id_seq"
    bigint_primary_key_index_name = "index_#{TABLE_NAME}_on_id_convert_to_bigint"
    temp_name = quote_column_name(:id_tmp)
    id_name = quote_column_name(:id)
    id_convert_to_bigint_name = quote_column_name(:id_convert_to_bigint)
    function_name = quote_table_name(
      Gitlab::Database::UnidirectionalCopyTrigger.on_table(
        TABLE_NAME, connection: Ci::ApplicationRecord.connection
      ).name(:id, :id_convert_to_bigint)
    )

    # 2. Create indexes using the bigint columns that match the existing indexes using the integer column
    # NOTE: this index is already created in:
    # - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120946
    # - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120950
    # Therefore, this won't have any effect for `up` step, but will be used for `down` step.
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: bigint_primary_key_index_name

    # 4. Inside a transaction, swap the columns
    # When stepping up, it will swap the bigint column as the primary key and the int column as `bigint`
    # When stepping down, it will swap the int column as the primary key and the bigint column as `bigint`
    with_lock_retries(raise_on_exhaustion: true) do
      # a. Lock the tables involved.
      execute "LOCK TABLE #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      # b. Rename the columns to swap names
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{id_name} TO #{temp_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{id_convert_to_bigint_name} TO #{id_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{temp_name} TO #{id_convert_to_bigint_name}"

      # c. Reset the trigger function
      execute "ALTER FUNCTION #{function_name} RESET ALL"

      # d. Swap the defaults
      execute "ALTER SEQUENCE #{sequence_name} OWNED BY #{TABLE_NAME}.id"
      change_column_default TABLE_NAME, :id, -> { "nextval('#{sequence_name}'::regclass)" }
      change_column_default TABLE_NAME, :id_convert_to_bigint, 0

      # e. Swap the PK constraint
      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT #{primary_key_constraint_name} CASCADE"
      rename_index TABLE_NAME, bigint_primary_key_index_name, primary_key_constraint_name
      execute <<~SQL
        ALTER TABLE #{TABLE_NAME}
        ADD CONSTRAINT #{primary_key_constraint_name} PRIMARY KEY
        USING INDEX #{primary_key_constraint_name}
      SQL
    end

    return unless stepping_down

    # For stepping down, we will need to recreate the index after the swap
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: bigint_primary_key_index_name
  end
end
