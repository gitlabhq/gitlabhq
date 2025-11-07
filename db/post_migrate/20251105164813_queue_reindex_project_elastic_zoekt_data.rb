# frozen_string_literal: true

class QueueReindexProjectElasticZoektData < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "ReindexProjectElasticZoektData"

  def up
    return unless Gitlab.com?

    queue_batched_background_migration(MIGRATION, :namespace_settings, :namespace_id)
  end

  def down
    return unless Gitlab.com?

    delete_batched_background_migration(MIGRATION, :namespace_settings, :namespace_id, [])
  end
end
