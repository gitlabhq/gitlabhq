# frozen_string_literal: true

class RemoveContainerRepositoryUpdatedEvents < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    drop_table :geo_container_repository_updated_events
  end

  def down
    create_table :geo_container_repository_updated_events, id: :bigserial do |t|
      t.integer :container_repository_id,
        null: false,
        index: { name: :idx_geo_con_rep_updated_events_on_container_repository_id }
    end

    add_concurrent_foreign_key :geo_container_repository_updated_events, :container_repositories,
                               column: :container_repository_id,
                               name: 'fk_212c89c706',
                               on_delete: :cascade
  end
end
