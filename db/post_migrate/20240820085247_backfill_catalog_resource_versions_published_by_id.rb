# frozen_string_literal: true

class BackfillCatalogResourceVersionsPublishedById < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 250

  def up
    catalog_resource_versions_model = define_batchable_model('catalog_resource_versions')

    catalog_resource_versions_model
      .where(published_by_id: nil)
      .each_batch(of: BATCH_SIZE) do |relation|
      connection.execute(
        <<~SQL
          UPDATE catalog_resource_versions
          SET published_by_id = releases.author_id
          FROM releases
          WHERE catalog_resource_versions.release_id = releases.id
          AND catalog_resource_versions.id IN (#{relation.select(:id).to_sql})
        SQL
      )
    end
  end

  def down
    # noop
  end
end
