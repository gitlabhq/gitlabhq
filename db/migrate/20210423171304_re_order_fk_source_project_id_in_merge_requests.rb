# frozen_string_literal: true

class ReOrderFkSourceProjectIdInMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  OLD_SOURCE_PROJECT_FK = 'fk_3308fe130c'
  NEW_SOURCE_PROJECT_FK = 'fk_source_project'

  def up
    add_concurrent_foreign_key :merge_requests, :projects, column: :source_project_id, on_delete: :nullify, name: NEW_SOURCE_PROJECT_FK

    remove_foreign_key_if_exists :merge_requests, column: :source_project_id, name: OLD_SOURCE_PROJECT_FK
  end

  def down
    add_concurrent_foreign_key :merge_requests, :projects, column: :source_project_id, on_delete: :nullify

    remove_foreign_key_if_exists :merge_requests, column: :source_project_id, name: NEW_SOURCE_PROJECT_FK
  end
end
