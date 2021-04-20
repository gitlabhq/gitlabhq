# frozen_string_literal: true

class AddClustersIntegrationsPrometheus < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      create_table :clusters_integration_prometheus, id: false do |t|
        t.timestamps_with_timezone null: false
        t.references :cluster, primary_key: true, default: nil, index: false, foreign_key: { on_delete: :cascade }
        t.boolean :enabled, null: false, default: false
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :clusters_integration_prometheus
    end
  end
end
