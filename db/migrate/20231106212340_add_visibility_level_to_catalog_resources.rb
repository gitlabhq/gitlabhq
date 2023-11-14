# frozen_string_literal: true

class AddVisibilityLevelToCatalogResources < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  enable_lock_retries!

  def change
    # This column must match the settings of `visibility_level` in the `projects` table.
    # Backfill will be done as part of https://gitlab.com/gitlab-org/gitlab/-/issues/429056.
    add_column :catalog_resources, :visibility_level, :integer, default: 0, null: false
  end
end
