# frozen_string_literal: true

class DropInvalidAsyncIndexFromPostgresAsyncIndex < Gitlab::Database::Migration[2.1]
  # rollback 20230117092947_add_tmp_index_to_ci_build_report_results.rb
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_ci_build_report_results_on_partition_id_and_id'
  TABLE_NAME = 'ci_build_report_results'

  def up
    return unless Gitlab.com?

    unprepare_async_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    return unless Gitlab.com?

    prepare_async_index(TABLE_NAME, [:partition_id, :id], where: 'partition_id = 101', name: INDEX_NAME)
  end
end
