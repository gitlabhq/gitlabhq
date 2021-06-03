# frozen_string_literal: true

class CleanUpRenameExperimentSubjectsGroupIdToNamespaceId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers::V2

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :experiment_subjects, :group_id, :namespace_id
  end

  def down
    undo_cleanup_concurrent_column_rename :experiment_subjects, :group_id, :namespace_id
  end
end
