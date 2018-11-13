# frozen_string_literal: true

class AddProjectsPoolRepositoryIdForeignKey < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :projects,
      :repositories,
      column: :pool_repository_id,
      on_delete: :nullify
    )
  end

  def down
    remove_foreign_key(:projects, column: :pool_repository_id)
  end
end
