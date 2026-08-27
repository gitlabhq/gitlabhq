# frozen_string_literal: true

class CreateCiTestBalancingTestSplits < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    create_table :ci_test_balancing_test_splits do |t|
      t.bigint :project_id, null: false
      t.datetime_with_timezone :last_seen_at, null: false, default: -> { 'NOW()' }
      t.text :path, null: false, limit: 1024

      t.index [:project_id, :path], unique: true, name: 'index_ci_test_balancing_test_splits_on_project_id_and_path'
    end
  end
end
