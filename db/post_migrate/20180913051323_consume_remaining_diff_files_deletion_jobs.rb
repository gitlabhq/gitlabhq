# frozen_string_literal: true

class ConsumeRemainingDiffFilesDeletionJobs < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  MIGRATION = 'ScheduleDiffFilesDeletion'.freeze
  TMP_INDEX = 'tmp_partial_diff_id_with_files_index'.freeze

  def up
    # Perform any ongoing background migration that might still be scheduled.
    Gitlab::BackgroundMigration.steal(MIGRATION)

    remove_concurrent_index_by_name(:merge_request_diffs, TMP_INDEX)
  end

  def down
    add_concurrent_index(:merge_request_diffs, :id, where: "(state NOT IN ('without_files', 'empty'))", name: TMP_INDEX)
  end
end
