# frozen_string_literal: true

class CreateCiRunnerMachines < Gitlab::Database::Migration[2.1]
  def change
    create_table :ci_runner_machines do |t|
      t.belongs_to :runner, index: false, null: false, foreign_key: { to_table: :ci_runners, on_delete: :cascade }
      t.integer :executor_type, limit: 2
      t.text :machine_xid, null: false, limit: 64
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :contacted_at
      t.text :version, limit: 2048
      t.text :revision, limit: 255
      t.text :platform, limit: 255
      t.text :architecture, limit: 255
      t.text :ip_address, limit: 1024

      t.index [:runner_id, :machine_xid], unique: true
      t.index :version
    end
  end
end
