# frozen_string_literal: true

class QueueDeleteTwitterIdentities < Gitlab::Database::Migration[2.2]
  MIGRATION = 'DeleteTwitterIdentities'

  disable_ddl_transaction!
  milestone '18.0'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :identities,
      :id
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :identities, :id, [])
  end
end
