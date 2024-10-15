# frozen_string_literal: true

class DeleteProjectImportDataWithoutProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute("DELETE FROM project_import_data WHERE project_id IS NULL")
  end

  def down
    # no-op
  end
end
