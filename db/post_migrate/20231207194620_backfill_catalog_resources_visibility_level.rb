# frozen_string_literal: true

class BackfillCatalogResourcesVisibilityLevel < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    sql = <<-SQL
      UPDATE catalog_resources
      SET visibility_level = projects.visibility_level
      FROM projects
      WHERE catalog_resources.project_id = projects.id
    SQL

    execute(sql)
  end

  def down
    # no-op

    # The `visibility_level` column in `catalog_resources` is denormalized;
    # it should always stay in sync with the corresponding data in `projects`.
  end
end
