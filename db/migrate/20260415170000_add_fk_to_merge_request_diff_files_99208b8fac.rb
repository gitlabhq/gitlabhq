# frozen_string_literal: true

class AddFkToMergeRequestDiffFiles99208b8fac < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.0'

  disable_ddl_transaction!

  TABLE_NAME = :merge_request_diff_files_99208b8fac
  FK_PROJECT_ID = :fk_rails_ebcce501f5
  FK_MR_DIFF_ID = :fk_rails_6fff895059

  def change
    # no-op: This caused timeouts on Group and Project deletion due to the missing indices.
    #  We would have to re-introduce the FK once the index creation has been completed.
  end
end
