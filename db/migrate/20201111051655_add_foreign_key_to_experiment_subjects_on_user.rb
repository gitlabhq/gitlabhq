# frozen_string_literal: true

class AddForeignKeyToExperimentSubjectsOnUser < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_concurrent_foreign_key :experiment_subjects, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :experiment_subjects, column: :user_id
    end
  end
end
