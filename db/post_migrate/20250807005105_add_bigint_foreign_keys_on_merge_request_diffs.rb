# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddBigintForeignKeysOnMergeRequestDiffs < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  TABLE_NAME = 'merge_request_diffs'
  COLUMNS = %i[id merge_request_id].freeze
  FOREIGN_KEYS = [
    {
      source_table: :merge_request_diffs,
      column: :merge_request_id_convert_to_bigint,
      target_table: :merge_requests,
      target_column: :id,
      on_delete: :cascade,
      name: :fk_8483f3258f
    },
    {
      source_table: :merge_requests,
      column: :latest_merge_request_diff_id,
      target_table: :merge_request_diffs,
      target_column: :id_convert_to_bigint,
      on_delete: :nullify,
      name: :fk_06067f5644
    },
    {
      source_table: :merge_request_diff_commits,
      column: :merge_request_diff_id,
      target_table: :merge_request_diffs,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_316aaceda3
    },
    {
      source_table: :merge_request_diff_files,
      column: :merge_request_diff_id,
      target_table: :merge_request_diffs,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_501aa0a391
    },
    {
      source_table: :merge_request_diff_details,
      column: :merge_request_diff_id,
      target_table: :merge_request_diffs,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_86f4d24ecd
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
        reverse_lock_order: true
      )

      prepare_async_foreign_key_validation fk[:source_table], fk[:column], name: tmp_name(fk[:name])
    end
  end

  def down
    FOREIGN_KEYS.each do |fk|
      remove_foreign_key_if_exists(
        fk[:source_table],
        fk[:target_table],
        name: tmp_name(fk[:name]),
        reverse_lock_order: true
      )

      unprepare_async_foreign_key_validation fk[:source_table], fk[:column], name: tmp_name(fk[:name])
    end
  end

  private

  def tmp_name(name)
    "#{name}_tmp"
  end
end
