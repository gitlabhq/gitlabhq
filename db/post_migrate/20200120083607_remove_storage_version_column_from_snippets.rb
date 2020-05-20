# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveStorageVersionColumnFromSnippets < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return unless column_exists?(:snippets, :storage_version)

    remove_column :snippets, :storage_version
  end

  def down
    return if column_exists?(:snippets, :storage_version)

    add_column_with_default( # rubocop:disable Migration/AddColumnWithDefault
      :snippets,
      :storage_version,
      :integer,
      default: 2,
      allow_null: false
    )
  end
end
