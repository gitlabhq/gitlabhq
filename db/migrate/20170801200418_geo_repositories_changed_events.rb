class GeoRepositoriesChangedEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :geo_repositories_changed_events, id: :bigserial do |t|
      t.references :geo_node, index: true, foreign_key: { on_delete: :cascade }, null: false
    end

    add_column :geo_event_log, :repositories_changed_event_id, :integer, limit: 8
  end
end
