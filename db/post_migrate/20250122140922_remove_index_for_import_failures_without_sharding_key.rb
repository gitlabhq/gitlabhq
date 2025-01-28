# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveIndexForImportFailuresWithoutShardingKey < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  INDEX_NAME = 'idx_import_failures_where_organization_project_and_group_null'

  def up
    remove_concurrent_index_by_name :import_failures, INDEX_NAME
  end

  def down
    add_concurrent_index(
      :import_failures,
      :id,
      where: "organization_id IS NULL AND project_id IS NULL AND group_id IS NULL",
      name: INDEX_NAME
    )
  end
end
