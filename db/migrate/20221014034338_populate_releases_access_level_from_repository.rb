# frozen_string_literal: true

class PopulateReleasesAccessLevelFromRepository < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  def up
    update_column_in_batches(
      :project_features,
      :releases_access_level,
      Arel.sql('repository_access_level')
    ) do |table, query|
      query.where(table[:releases_access_level].gt(table[:repository_access_level]))
    end
  end

  def down
    # no-op
  end
end
