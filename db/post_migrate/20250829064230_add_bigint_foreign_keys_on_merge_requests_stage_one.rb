# frozen_string_literal: true

class AddBigintForeignKeysOnMergeRequestsStageOne < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  TABLE_NAME = 'merge_requests'
  COLUMNS = %i[assignee_id merge_user_id updated_by_id milestone_id source_project_id].freeze
  FOREIGN_KEYS = [
    {
      source_table: :merge_requests,
      column: :assignee_id_convert_to_bigint,
      target_table: :users,
      target_column: :id,
      on_delete: :nullify,
      name: :fk_6149611a04
    },
    {
      source_table: :merge_requests,
      column: :updated_by_id_convert_to_bigint,
      target_table: :users,
      target_column: :id,
      on_delete: :nullify,
      name: :fk_641731faff
    },
    {
      source_table: :merge_requests,
      column: :milestone_id_convert_to_bigint,
      target_table: :milestones,
      target_column: :id,
      on_delete: :nullify,
      name: :fk_6a5165a692
    },
    {
      source_table: :merge_requests,
      column: :merge_user_id_convert_to_bigint,
      target_table: :users,
      target_column: :id,
      on_delete: :nullify,
      name: :fk_ad525e1f87
    },
    {
      source_table: :merge_requests,
      column: :source_project_id_convert_to_bigint,
      target_table: :projects,
      target_column: :id,
      on_delete: :nullify,
      name: :fk_source_project
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
