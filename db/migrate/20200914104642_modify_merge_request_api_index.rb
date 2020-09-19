# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ModifyMergeRequestApiIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, [:target_project_id, :created_at, :id], name: :index_merge_requests_on_target_project_id_and_created_at_and_id
  end

  def down
    remove_concurrent_index :merge_requests, [:target_project_id, :created_at, :id], name: :index_merge_requests_on_target_project_id_and_created_at_and_id
  end
end
