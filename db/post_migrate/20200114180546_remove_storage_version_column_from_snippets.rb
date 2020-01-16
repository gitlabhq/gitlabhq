# frozen_string_literal: true

class RemoveStorageVersionColumnFromSnippets < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return unless column_exists?(:snippets, :storage_version)

    remove_column :snippets, :storage_version
  end

  def down
    add_column_with_default( # rubocop:disable Migration/AddColumnWithDefault
      :snippets,
      :storage_version,
      :integer,
      default: 2,
      allow_null: false
    )
  end
end
