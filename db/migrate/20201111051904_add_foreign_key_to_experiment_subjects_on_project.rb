# frozen_string_literal: true

class AddForeignKeyToExperimentSubjectsOnProject < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_concurrent_foreign_key :experiment_subjects, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :experiment_subjects, column: :project_id
    end
  end
end
