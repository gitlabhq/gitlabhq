# frozen_string_literal: true

class AddProjectIdToMergeRequestBlocks < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :merge_request_blocks, :project_id, :bigint
  end
end
