# frozen_string_literal: true

class AddProjectIdToMergeRequestAssignees < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :merge_request_assignees, :project_id, :bigint
  end
end
