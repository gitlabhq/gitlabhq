# frozen_string_literal: true

class BackfillCatalogResourcesNameAndDescription < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    sql = <<-SQL
      UPDATE catalog_resources
      SET name = projects.name,
          description = projects.description
      FROM projects
      WHERE catalog_resources.project_id = projects.id
    SQL

    execute(sql)
  end

  def down
    # no-op

    # The `name` and `description` columns in `catalog_resources` are denormalized;
    # they should always stay in sync with the corresponding data in `projects`.
  end
end
