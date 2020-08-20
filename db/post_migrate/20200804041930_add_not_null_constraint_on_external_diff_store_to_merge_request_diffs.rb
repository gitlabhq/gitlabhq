# frozen_string_literal: true

class AddNotNullConstraintOnExternalDiffStoreToMergeRequestDiffs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_not_null_constraint(:merge_request_diffs, :external_diff_store, validate: false)
  end

  def down
    remove_not_null_constraint(:merge_request_diffs, :external_diff_store)
  end
end
