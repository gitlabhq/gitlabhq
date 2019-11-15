# frozen_string_literal: true

class AddForeignKeyOnResolvedByIdToVulnerabilities < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerabilities, :resolved_by_id
    add_concurrent_foreign_key :vulnerabilities, :users, column: :resolved_by_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :vulnerabilities, column: :resolved_by_id
    remove_concurrent_index :vulnerabilities, :resolved_by_id
  end
end
