# frozen_string_literal: true

class AddProjectIdToMergeRequestAssignmentEvents < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :merge_request_assignment_events, :project_id, :bigint
  end
end
