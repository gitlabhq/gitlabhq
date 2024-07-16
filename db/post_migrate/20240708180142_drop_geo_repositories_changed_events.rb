# frozen_string_literal: true

class DropGeoRepositoriesChangedEvents < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  disable_ddl_transaction!

  def up
    drop_table :geo_repositories_changed_events
  end

  def down
    create_table :geo_repositories_changed_events do |t|
      t.integer :geo_node_id,
        index: { name: 'index_geo_repositories_changed_events_on_geo_node_id' },
        null: false
    end

    add_concurrent_foreign_key(
      :geo_repositories_changed_events,
      :geo_nodes,
      name: :fk_rails_75ec0fefcc,
      column: :geo_node_id,
      on_delete: :cascade
    )
  end
end
