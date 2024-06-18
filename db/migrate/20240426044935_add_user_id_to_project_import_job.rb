# frozen_string_literal: true

class AddUserIdToProjectImportJob < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :project_export_jobs, :user_id, :bigint, null: true
    end

    add_concurrent_foreign_key :project_export_jobs, :users, column: :user_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :project_export_jobs, column: :user_id
    end

    with_lock_retries do
      remove_column :project_export_jobs, :user_id
    end
  end
end
