# frozen_string_literal: true

class AddBigintForeignKeysOnMergeRequestsStageTwo < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.7'

  TABLE_NAME = 'merge_requests'
  COLUMNS = %i[target_project_id latest_merge_request_diff_id last_edited_by_id].freeze
  FOREIGN_KEYS = [
    {
      source_table: :merge_requests,
      column: :target_project_id_convert_to_bigint,
      target_table: :projects,
      target_column: :id,
      on_delete: :cascade,
      name: :fk_a6963e8447,
      reverse_lock_order: true
    },
    {
      source_table: :merge_requests,
      column: :latest_merge_request_diff_id_convert_to_bigint,
      target_table: :merge_request_diffs,
      target_column: :id,
      on_delete: :nullify,
      name: :fk_06067f5644,
      reverse_lock_order: true
    }
  ].freeze
  PARTITIONED_FOREIGN_KEYS = [
    {
      source_table: :p_generated_ref_commits,
      column: [:project_id, :merge_request_iid],
      target_table: :merge_requests,
      target_column: [:target_project_id_convert_to_bigint, :iid],
      on_delete: :cascade,
      name: :fk_generated_ref_commits_merge_request_id,
      reverse_lock_order: true
    }
  ].freeze

  def up
    conversion_needed = COLUMNS.all? do |column|
      column_exists?(TABLE_NAME, convert_to_bigint_column(column))
    end

    unless conversion_needed
      say "No conversion columns found - no need to create bigint FKs"
      return
    end

    FOREIGN_KEYS.each do |fk|
      add_concurrent_foreign_key(
        fk[:source_table],
        fk[:target_table],
        column: fk[:column],
        target_column: fk[:target_column],
        name: tmp_name(fk[:name]),
        on_delete: fk[:on_delete],
        validate: false,
        reverse_lock_order: fk[:reverse_lock_order]
      )

      prepare_async_foreign_key_validation fk[:source_table], fk[:column], name: tmp_name(fk[:name])
    end

    PARTITIONED_FOREIGN_KEYS.each do |fk|
      add_concurrent_partitioned_foreign_key(
        fk[:source_table],
        fk[:target_table],
        column: fk[:column],
        target_column: fk[:target_column],
        name: tmp_name(fk[:name]),
        on_delete: fk[:on_delete],
        validate: false,
        reverse_lock_order: fk[:reverse_lock_order]
      )

      prepare_partitioned_async_foreign_key_validation fk[:source_table], fk[:column], name: tmp_name(fk[:name])
    end
  end

  def down
    PARTITIONED_FOREIGN_KEYS.each do |fk|
      remove_partitioned_foreign_key(
        fk[:source_table],
        fk[:target_table],
        name: tmp_name(fk[:name]),
        reverse_lock_order: fk[:reverse_lock_order]
      )

      unprepare_async_foreign_key_validation fk[:source_table], fk[:column], name: tmp_name(fk[:name])
    end

    FOREIGN_KEYS.each do |fk|
      remove_foreign_key_if_exists(
        fk[:source_table],
        fk[:target_table],
        name: tmp_name(fk[:name]),
        reverse_lock_order: fk[:reverse_lock_order]
      )

      unprepare_async_foreign_key_validation fk[:source_table], fk[:column], name: tmp_name(fk[:name])
    end
  end

  private

  def tmp_name(name)
    "#{name}_tmp"
  end
end
