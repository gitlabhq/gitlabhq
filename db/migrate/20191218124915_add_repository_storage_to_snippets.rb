# frozen_string_literal: true

class AddRepositoryStorageToSnippets < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # rubocop:disable Migration/PreventStrings
  def up
    add_column_with_default(
      :snippets,
      :repository_storage,
      :string,
      default: 'default',
      limit: 255,
      allow_null: false
    )
  end
  # rubocop:enable Migration/PreventStrings

  def down
    remove_column(:snippets, :repository_storage)
  end
end
