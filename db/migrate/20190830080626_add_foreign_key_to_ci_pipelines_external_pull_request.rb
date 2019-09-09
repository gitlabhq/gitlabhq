# frozen_string_literal: true

class AddForeignKeyToCiPipelinesExternalPullRequest < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_pipelines, :external_pull_requests, column: :external_pull_request_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :ci_pipelines, :external_pull_requests
  end
end
