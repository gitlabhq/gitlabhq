# frozen_string_literal: true

# See https://docs.gitlab.com/development/migration_style_guide/
# for more information on how to write migrations for GitLab.

class AddUuidVersionToTrackedContext < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :security_project_tracked_contexts, :uuid_version, :smallint, default: 1, null: false
  end
end
