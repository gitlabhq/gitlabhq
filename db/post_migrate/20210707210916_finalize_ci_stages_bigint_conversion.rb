# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FinalizeCiStagesBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  TABLE_NAME = 'ci_stages'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [['id'], ['id_convert_to_bigint']]
    )

    swap
  end

  def down
    swap
  end

  def swap
    # This will replace the existing ci_stages_pkey index for the primary key
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: 'index_ci_stages_on_id_convert_to_bigint'

    # This will replace the existing ci_stages_on_pipeline_id_and_id index
    add_concurrent_index TABLE_NAME, [:pipeline_id, :id_convert_to_bigint],
                         name: 'index_ci_stages_on_pipeline_id_and_id_convert_to_bigint',
                         where: 'status in (0, 1, 2, 8, 9, 10)'

    # Add a foreign key on ci_builds(stage_id_convert_to_bigint), which we'll rename later. Give it the correct final name
    fk_stage_id = concurrent_foreign_key_name(:ci_builds, :stage_id)
    fk_stage_id_tmp = "#{fk_stage_id}_tmp"
    add_concurrent_foreign_key :ci_builds, :ci_stages, column: :stage_id,
                               target_column: :id_convert_to_bigint,
                               name: fk_stage_id_tmp,
                               on_delete: :cascade,
                               reverse_lock_order: true

    # Now it's time to do things in a transaction
    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE #{TABLE_NAME}, ci_builds IN ACCESS EXCLUSIVE MODE"

      temp_name = quote_column_name('id_tmp')
      id_name = quote_column_name(:id)
      id_convert_to_bigint_name = quote_column_name(:id_convert_to_bigint)
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{id_name} TO #{temp_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{id_convert_to_bigint_name} TO #{id_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{temp_name} TO #{id_convert_to_bigint_name}"

      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME).name(:id, :id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # Swap defaults
      execute "ALTER SEQUENCE ci_stages_id_seq OWNED BY #{TABLE_NAME}.id"
      change_column_default TABLE_NAME, :id, -> { "nextval('ci_stages_id_seq'::regclass)"}
      change_column_default TABLE_NAME, :id_convert_to_bigint, 0

      # Swap pkey constraint
      # This will drop fk_3a9eaa254d (ci_builds(stage_id) references ci_stages(id))
      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT ci_stages_pkey CASCADE"
      rename_index TABLE_NAME, 'index_ci_stages_on_id_convert_to_bigint', 'ci_stages_pkey'
      execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT ci_stages_pkey PRIMARY KEY USING INDEX ci_stages_pkey"

      # Rename the other indexes
      execute "DROP INDEX index_ci_stages_on_pipeline_id_and_id"
      rename_index TABLE_NAME, 'index_ci_stages_on_pipeline_id_and_id_convert_to_bigint', 'index_ci_stages_on_pipeline_id_and_id'

      rename_constraint(:ci_builds, fk_stage_id_tmp, fk_stage_id)
    end
  end
end
