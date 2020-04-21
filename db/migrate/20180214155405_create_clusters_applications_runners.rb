class CreateClustersApplicationsRunners < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :clusters_applications_runners do |t|
      t.references :cluster, null: false, foreign_key: { on_delete: :cascade }
      t.references :runner, references: :ci_runners
      t.index :runner_id
      t.index :cluster_id, unique: true
      t.integer :status, null: false
      t.timestamps_with_timezone null: false
      t.string :version, null: false # rubocop:disable Migration/PreventStrings
      t.text :status_reason # rubocop:disable Migration/AddLimitToTextColumns
    end

    add_concurrent_foreign_key :clusters_applications_runners, :ci_runners,
      column: :runner_id,
      on_delete: :nullify
  end

  def down
    if foreign_keys_for(:clusters_applications_runners, :runner_id).any?
      remove_foreign_key :clusters_applications_runners, column: :runner_id
    end

    drop_table :clusters_applications_runners
  end
end
