# frozen_string_literal: true

class RenameExperimentSubjectsGroupIdToNamespaceId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers::V2

  disable_ddl_transaction!

  def up
    rename_column_concurrently :experiment_subjects, :group_id, :namespace_id
  end

  def down
    undo_rename_column_concurrently :experiment_subjects, :group_id, :namespace_id
  end
end
