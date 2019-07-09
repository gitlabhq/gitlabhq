# frozen_string_literal: true

class AddForeignKeysForContainerRepository < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:geo_container_repository_updated_events, :container_repositories, column: :container_repository_id, on_delete: :cascade)

    add_concurrent_foreign_key(:geo_event_log, :geo_container_repository_updated_events, column: :container_repository_updated_event_id, on_delete: :cascade)
  end

  def down
    if foreign_key_exists?(:geo_container_repository_updated_events, :container_repositories)
      remove_foreign_key(:geo_container_repository_updated_events, :container_repositories)
    end

    if foreign_key_exists?(:geo_event_log, :geo_container_repository_updated_events)
      remove_foreign_key(:geo_event_log, :geo_container_repository_updated_events)
    end
  end
end
