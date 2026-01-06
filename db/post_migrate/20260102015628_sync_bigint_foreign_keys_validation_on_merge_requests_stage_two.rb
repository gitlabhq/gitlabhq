# frozen_string_literal: true

class SyncBigintForeignKeysValidationOnMergeRequestsStageTwo < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '18.8'

  TABLE_NAME = 'merge_requests'
  COLUMNS = %i[target_project_id latest_merge_request_diff_id last_edited_by_id].freeze
  FOREIGN_KEYS = [
    {
      source_table: :merge_requests,
      column: :target_project_id_convert_to_bigint,
      name: :fk_a6963e8447
    },
    {
      source_table: :merge_requests,
      column: :latest_merge_request_diff_id_convert_to_bigint,
      name: :fk_06067f5644
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

    # synchronously validates un-partitioned FKs
    FOREIGN_KEYS.each do |fk|
      validate_foreign_key fk[:source_table], fk[:column], name: tmp_name(fk[:name])
    end

    # synchronously validates partitioned FKs
    PARTITIONED_FOREIGN_KEYS.each do |fk|
      add_concurrent_partitioned_foreign_key(
        fk[:source_table],
        fk[:target_table],
        column: fk[:column],
        target_column: fk[:target_column],
        name: tmp_name(fk[:name]),
        on_delete: fk[:on_delete],
        validate: true,
        reverse_lock_order: fk[:reverse_lock_order]
      )
    end
  end

  def down
    # no-op
  end

  private

  def tmp_name(name)
    "#{name}_tmp"
  end
end
