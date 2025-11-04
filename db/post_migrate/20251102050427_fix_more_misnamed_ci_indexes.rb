# frozen_string_literal: true

class FixMoreMisnamedCiIndexes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  # Mapping of table names -> [index columns, old name, expected name]
  # rubocop:disable Layout/LineLength -- More readable on single line
  INDEXES_TO_RENAME = {
    'p_ci_builds' => [
      [%w[stage_id], 'p_ci_builds_stage_id_convert_to_bigint_idx', 'p_ci_builds_stage_id_idx']
    ],
    'p_ci_pipelines' => [
      [%w[auto_canceled_by_id], 'p_ci_pipelines_auto_canceled_by_id_convert_to_bigint_idx', 'p_ci_pipelines_auto_canceled_by_id_idx']
    ]
  }.freeze
  # rubocop:enable Layout/LineLength

  def up
    with_each_index do |table, columns, old_name, new_name|
      next if index_exists?(table, columns, name: new_name)
      next unless index_exists?(table, columns, name: old_name)

      with_lock_retries { rename_index(table, old_name, new_name) }
    end
  end

  # We have no way of tracking which misnamed indexes existed before the migration,
  # so let's not try to restore the previous, incorrect state.
  def down; end

  private

  def with_each_index
    INDEXES_TO_RENAME.each do |table, indexes|
      indexes.each do |index_info|
        columns, old_name, new_name = index_info
        yield table, columns, old_name, new_name
      end
    end
  end
end
