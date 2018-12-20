# frozen_string_literal: true

class AddAuthorIdIndexAndFkToReleases < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :releases, :author_id

    add_concurrent_foreign_key :releases, :users, column: :author_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :releases, column: :author_id

    remove_concurrent_index :releases, column: :author_id
  end
end
