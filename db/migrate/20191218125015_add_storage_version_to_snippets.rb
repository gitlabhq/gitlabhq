# frozen_string_literal: true

class AddStorageVersionToSnippets < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_column_with_default( # rubocop:disable Migration/AddColumnWithDefault
      :snippets,
      :storage_version,
      :integer,
      default: 2,
      allow_null: false
    )
  end

  def down
    remove_column(:snippets, :storage_version)
  end
end
