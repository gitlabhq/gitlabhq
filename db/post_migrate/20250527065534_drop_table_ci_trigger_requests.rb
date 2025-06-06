# frozen_string_literal: true

class DropTableCiTriggerRequests < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      drop_table(:ci_trigger_requests, if_exists: true)
    end
  end

  def down
    with_lock_retries do
      create_table(:ci_trigger_requests, id: :bigserial, if_not_exists: true) do |t|
        t.bigint :trigger_id, null: false
        t.bigint :commit_id
        t.bigint :project_id
        t.timestamps_with_timezone
        t.text :variables
      end
    end

    add_concurrent_index(:ci_trigger_requests, :commit_id, name: :index_ci_trigger_requests_on_commit_id,
      if_not_exists: true)
    add_concurrent_index(:ci_trigger_requests, :project_id, name: :index_ci_trigger_requests_on_project_id,
      if_not_exists: true)
    add_concurrent_index(:ci_trigger_requests, [:trigger_id, :id],
      name: :index_ci_trigger_requests_on_trigger_id_and_id, order: { id: :desc }, if_not_exists: true)
    add_not_null_constraint(:ci_trigger_requests, :project_id)
  end
end
