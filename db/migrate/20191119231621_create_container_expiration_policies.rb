# frozen_string_literal: true

class CreateContainerExpirationPolicies < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :container_expiration_policies, id: false, primary_key: :project_id do |t|
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :next_run_at
      t.references :project, primary_key: true, default: nil, index: false, foreign_key: { on_delete: :cascade }
      t.string :name_regex, limit: 255
      t.string :cadence, null: false, limit: 12, default: '7d'
      t.string :older_than, limit: 12
      t.integer :keep_n
      t.boolean :enabled, null: false, default: false
    end

    add_index :container_expiration_policies, [:next_run_at, :enabled],
              name: 'index_container_expiration_policies_on_next_run_at_and_enabled'
  end
end
