# frozen_string_literal: true

class CreateCiTestBalancingJobGroups < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    create_table :ci_test_balancing_job_groups do |t|
      t.bigint :project_id, null: false
      t.datetime_with_timezone :last_seen_at, null: false, default: -> { 'NOW()' }
      t.text :name, null: false, limit: 255

      t.index [:project_id, :name], unique: true, name: 'index_ci_test_balancing_job_groups_on_project_id_and_name'
    end
  end
end
