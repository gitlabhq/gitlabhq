# frozen_string_literal: true

class RemoveForeignKeyGeoRepositoryUpdatedEvents < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  FROM_TABLE = :geo_repository_updated_events
  TO_TABLE = :projects

  def up
    with_lock_retries do
      remove_foreign_key(
        FROM_TABLE,
        TO_TABLE,
        column: :project_id,
        if_exists: true
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      FROM_TABLE,
      TO_TABLE,
      name: :fk_rails_2b70854c08,
      column: :project_id,
      on_delete: :cascade
    )
  end
end
