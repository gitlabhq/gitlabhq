# frozen_string_literal: true

class IndexTimestampColumnsForMergeRequestsCreationDate < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(*index_arguments)
  end

  def down
    remove_concurrent_index(*index_arguments)
  end

  private

  def index_arguments
    [
      :merge_requests,
      [:target_project_id, :created_at],
      {
        name: 'index_merge_requests_target_project_id_created_at'
      }
    ]
  end
end
