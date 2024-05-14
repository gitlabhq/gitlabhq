# frozen_string_literal: true

class MigrateInputsToSpecOnCatalogResourceComponents < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '16.11'

  disable_ddl_transaction!

  def up
    each_batch_range('catalog_resource_components') do |min, max|
      execute <<~SQL
        UPDATE catalog_resource_components
        SET spec = jsonb_set('{}'::jsonb, '{inputs}', inputs::jsonb)
        WHERE id BETWEEN #{min} AND #{max}
        AND spec = '{}' AND inputs <> '{}'
      SQL
    end
  end

  def down
    # no-op
  end
end
