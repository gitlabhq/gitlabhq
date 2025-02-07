# frozen_string_literal: true

class AddProjectIdToMergeRequestDiffDetails < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :merge_request_diff_details, :project_id, :bigint
  end
end
