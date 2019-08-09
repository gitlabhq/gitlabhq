# frozen_string_literal: true

class AddIndexToCiPipelinesExternalPullRequest < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, :external_pull_request_id, where: 'external_pull_request_id IS NOT NULL'
  end

  def down
    remove_concurrent_index :ci_pipelines, :external_pull_request_id
  end
end
