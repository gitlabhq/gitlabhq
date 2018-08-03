# frozen_string_literal: true
class CreateCiBuildEnvironmentDeployments < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :ci_build_environment_deployments do |t|
      t.integer :build_id, null: false
      t.integer :environment_id, null: false
      t.integer :deployment_id
      t.timestamps_with_timezone null: false

      t.foreign_key :ci_builds, column: :build_id, on_delete: :cascade
      t.foreign_key :environments, column: :environment_id, on_delete: :cascade
      t.foreign_key :deployments, column: :deployment_id, on_delete: :cascade

      t.index [:build_id, :environment_id], unique: true, name: 'index_ci_build_id_and_environment_id'
    end
  end
end
