# frozen_string_literal: true

class AddProjectIdToMergeRequestDiffFiles99208b8fac < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def up
    add_column :merge_request_diff_files_99208b8fac, :project_id, :bigint # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
  end

  def down
    remove_column :merge_request_diff_files_99208b8fac, :project_id
  end
end
