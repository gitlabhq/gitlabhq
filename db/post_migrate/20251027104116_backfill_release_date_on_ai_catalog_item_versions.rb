# frozen_string_literal: true

class BackfillReleaseDateOnAiCatalogItemVersions < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    sql = <<~SQL
      UPDATE "ai_catalog_item_versions"
      SET "release_date" = "created_at"
      WHERE "release_date" IS NULL;
    SQL

    execute(sql)
  end

  def down
    # no-op
    # Reason: Cannot safely reverse this migration as we cannot distinguish between
    # release_date values that were backfilled by this migration versus those that were already set.
  end
end
