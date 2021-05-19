# frozen_string_literal: true

class CreateClustersIntegrationElasticstack < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def change
    create_table_with_constraints :clusters_integration_elasticstack, id: false do |t|
      t.timestamps_with_timezone null: false
      t.references :cluster, primary_key: true, default: nil, index: false, foreign_key: { on_delete: :cascade }
      t.boolean :enabled, null: false, default: false
      t.text :chart_version
      t.text_limit :chart_version, 10
    end
  end
end
