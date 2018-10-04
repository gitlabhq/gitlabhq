class EnqueueDeleteDiffFilesWorkers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  SCHEDULER = 'ScheduleDiffFilesDeletion'.freeze
  TMP_INDEX = 'tmp_partial_diff_id_with_files_index'.freeze

  disable_ddl_transaction!

  def up
    unless index_exists_by_name?(:merge_request_diffs, TMP_INDEX)
      add_concurrent_index(:merge_request_diffs, :id, where: "(state NOT IN ('without_files', 'empty'))", name: TMP_INDEX)
    end

    BackgroundMigrationWorker.perform_async(SCHEDULER)

    # We don't remove the index since it's going to be used on DeleteDiffFiles
    # worker. We should remove it in an upcoming release.
  end

  def down
    if index_exists_by_name?(:merge_request_diffs, TMP_INDEX)
      remove_concurrent_index_by_name(:merge_request_diffs, TMP_INDEX)
    end
  end
end
