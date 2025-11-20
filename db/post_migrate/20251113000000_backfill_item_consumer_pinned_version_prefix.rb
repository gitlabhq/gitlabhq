# frozen_string_literal: true

class BackfillItemConsumerPinnedVersionPrefix < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute <<~SQL
      UPDATE ai_catalog_item_consumers
      SET pinned_version_prefix = (
        SELECT version
        FROM ai_catalog_item_versions
        WHERE ai_catalog_item_versions.ai_catalog_item_id = ai_catalog_item_consumers.ai_catalog_item_id
        ORDER BY created_at DESC
        LIMIT 1
      )
      WHERE pinned_version_prefix IS NULL
    SQL
  end

  def down
    # No-op: we cannot restore NULL values
  end
end
