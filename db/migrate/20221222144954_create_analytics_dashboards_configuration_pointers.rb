# frozen_string_literal: true

class CreateAnalyticsDashboardsConfigurationPointers < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    create_table :analytics_dashboards_pointers do |t|
      t.belongs_to :namespace,
                   null: false,
                   index: { unique: true },
                   foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.belongs_to :project, null: false, foreign_key: { to_table: :projects, on_delete: :cascade }
    end
  end

  def down
    drop_table :analytics_dashboards_pointers
  end
end
