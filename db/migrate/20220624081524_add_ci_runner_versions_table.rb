# frozen_string_literal: true

class AddCiRunnerVersionsTable < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    create_table :ci_runner_versions, id: false do |t|
      t.text :version, primary_key: true, index: true, null: false, limit: 2048
      t.integer :status, null: true, limit: 2, index: true
    end
  end

  def down
    drop_table :ci_runner_versions, if_exists: true
  end
end
