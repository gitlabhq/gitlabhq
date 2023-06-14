# frozen_string_literal: true

class SwapNotesIdToBigintForGitlabDotCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = 'notes'
  PK_INDEX_NAME = 'index_notes_on_id_convert_to_bigint'

  SECONDARY_INDEXES = [
    {
      original_name: :index_notes_on_author_id_and_created_at_and_id,
      temporary_name: :index_notes_on_author_id_created_at_id_convert_to_bigint,
      columns: [:author_id, :created_at, :id_convert_to_bigint],
      options: {}
    },
    {
      original_name: :index_notes_on_id_where_confidential,
      temporary_name: :index_notes_on_id_convert_to_bigint_where_confidential,
      columns: [:id_convert_to_bigint],
      options: { where: 'confidential = true' }
    },
    {
      original_name: :index_notes_on_id_where_internal,
      temporary_name: :index_notes_on_id_convert_to_bigint_where_internal,
      columns: [:id_convert_to_bigint],
      options: { where: 'internal = true' }
    },
    {
      original_name: :index_notes_on_project_id_and_id_and_system_false,
      temporary_name: :index_notes_on_project_id_id_convert_to_bigint_system_false,
      columns: [:project_id, :id_convert_to_bigint],
      options: { where: 'NOT system' }
    },
    {
      original_name: :note_mentions_temp_index,
      temporary_name: :note_mentions_temp_index_convert_to_bigint,
      columns: [:id_convert_to_bigint, :noteable_type],
      options: { where: "note ~~ '%@%'::text" }
    }
  ]

  REFERENCING_FOREIGN_KEYS = [
    [:todos, :fk_91d1f47b13, :note_id, :cascade],
    [:incident_management_timeline_events, :fk_d606a2a890, :promoted_from_note_id, :nullify],
    [:system_note_metadata, :fk_d83a918cb1, :note_id, :cascade],
    [:diff_note_positions, :fk_rails_13c7212859, :note_id, :cascade],
    [:epic_user_mentions, :fk_rails_1c65976a49, :note_id, :cascade],
    [:suggestions, :fk_rails_33b03a535c, :note_id, :cascade],
    [:issue_user_mentions, :fk_rails_3861d9fefa, :note_id, :cascade],
    [:note_diff_files, :fk_rails_3d66047aeb, :diff_note_id, :cascade],
    [:snippet_user_mentions, :fk_rails_4d3f96b2cb, :note_id, :cascade],
    [:design_user_mentions, :fk_rails_8de8c6d632, :note_id, :cascade],
    [:vulnerability_user_mentions, :fk_rails_a18600f210, :note_id, :cascade],
    [:commit_user_mentions, :fk_rails_a6760813e0, :note_id, :cascade],
    [:merge_request_user_mentions, :fk_rails_c440b9ea31, :note_id, :cascade],
    [:note_metadata, :fk_rails_d853224d37, :note_id, :cascade],
    [:alert_management_alert_user_mentions, :fk_rails_eb2de0cdef, :note_id, :cascade],
    [:timelogs, :fk_timelogs_note_id, :note_id, :nullify]
  ]

  def up
    return unless should_run?

    swap
  end

  def down
    return unless should_run?

    swap

    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: PK_INDEX_NAME

    REFERENCING_FOREIGN_KEYS.each do |(from_table, name, column, on_delete)|
      temporary_name = "#{name}_tmp"

      add_concurrent_foreign_key(
        from_table,
        TABLE_NAME,
        column: column,
        target_column: :id_convert_to_bigint,
        name: temporary_name,
        on_delete: on_delete,
        reverse_lock_order: true,
        validate: false)
    end
  end

  def swap
    # Copy existing indexes from the original column to the new column
    create_indexes

    # Copy existing FKs from the original column to the new column
    create_referencing_foreign_keys

    # Remove existing FKs from the referencing tables, so we don't have to lock on them when we drop the existing PK
    replace_referencing_foreign_keys

    with_lock_retries(raise_on_exhaustion: true) do
      # Swap the original and new column names
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN id TO id_tmp"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN id_convert_to_bigint TO id"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN id_tmp TO id_convert_to_bigint"

      # Reset the function so PG drops the plan cache for the incorrect integer type
      function_name = Gitlab::Database::UnidirectionalCopyTrigger
        .on_table(TABLE_NAME, connection: connection)
        .name(:id, :id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # Swap defaults of the two columns, and change ownership of the sequence to the new id
      execute "ALTER SEQUENCE notes_id_seq OWNED BY #{TABLE_NAME}.id"
      change_column_default TABLE_NAME, :id, -> { "nextval('notes_id_seq'::regclass)" }
      change_column_default TABLE_NAME, :id_convert_to_bigint, 0

      # Swap the PK constraint from the original column to the new column.
      # We deliberately don't CASCADE here because the old FKs should be removed already
      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT notes_pkey"
      rename_index TABLE_NAME, PK_INDEX_NAME, 'notes_pkey'
      execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT notes_pkey PRIMARY KEY USING INDEX notes_pkey"

      # Remove old column indexes and change new column indexes to have the original names
      rename_secondary_indexes # rubocop:disable Migration/WithLockRetriesDisallowedMethod
    end
  end

  private

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end

  def create_indexes
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: PK_INDEX_NAME

    SECONDARY_INDEXES.each do |index_definition|
      options = index_definition[:options]
      options[:name] = index_definition[:temporary_name]

      add_concurrent_index(TABLE_NAME, index_definition[:columns], options)
    end
  end

  def rename_secondary_indexes
    SECONDARY_INDEXES.each do |index_definition|
      remove_index(TABLE_NAME, name: index_definition[:original_name], if_exists: true) # rubocop:disable Migration/RemoveIndex
      rename_index(TABLE_NAME, index_definition[:temporary_name], index_definition[:original_name])
    end
  end

  def create_referencing_foreign_keys
    REFERENCING_FOREIGN_KEYS.each do |(from_table, name, column, on_delete)|
      # Don't attempt to create the FK if one already exists from the table to the new column
      # The check in `add_concurrent_foreign_key` already checks for this, but it looks for the foreign key
      # with the new name only (containing the `_tmp` suffix).
      #
      # Since we might partially rename FKs and re-run the migration, we also have to check and see if a FK exists
      # on those columns that might not match the `_tmp` name.
      next if foreign_key_exists?(
        from_table, TABLE_NAME, column: column,
        primary_key: :id_convert_to_bigint, name: name)

      temporary_name = "#{name}_tmp"

      add_concurrent_foreign_key(
        from_table,
        TABLE_NAME,
        column: column,
        target_column: :id_convert_to_bigint,
        name: temporary_name,
        on_delete: on_delete,
        reverse_lock_order: true)
    end
  end

  def replace_referencing_foreign_keys
    REFERENCING_FOREIGN_KEYS.each do |(from_table, name, column, _)|
      # Don't attempt to replace the FK unless it exists and points at the original column.
      # This could happen if the migration is re-run due to failing midway.
      next unless foreign_key_exists?(from_table, TABLE_NAME, column: column, primary_key: :id, name: name)

      with_lock_retries(raise_on_exhaustion: true) do
        temporary_name = "#{name}_tmp"

        # Explicitly lock table in order of parent, child to attempt to avoid deadlocks
        execute "LOCK TABLE #{TABLE_NAME}, #{from_table} IN ACCESS EXCLUSIVE MODE"

        remove_foreign_key(from_table, TABLE_NAME, column: column, primary_key: :id, name: name)
        rename_constraint(from_table, temporary_name, name)
      end
    end
  end
end
