# frozen_string_literal: true

class AddIndexOnMergeRequestDiffsExternalDiffStore < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_request_diffs, :external_diff_store
  end

  def down
    remove_concurrent_index :merge_request_diffs, :external_diff_store
  end
end
