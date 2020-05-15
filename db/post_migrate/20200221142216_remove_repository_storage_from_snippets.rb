# frozen_string_literal: true

class RemoveRepositoryStorageFromSnippets < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return unless column_exists?(:snippets, :repository_storage)

    remove_column :snippets, :repository_storage
  end

  def down
    return if column_exists?(:snippets, :repository_storage)

    add_column_with_default( # rubocop:disable Migration/AddColumnWithDefault
      :snippets,
      :repository_storage,
      :string,
      default: 'default',
      limit: 255,
      allow_null: false
    )
  end
end
