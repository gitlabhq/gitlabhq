# frozen_string_literal: true

class AddTargetProjectIdToMergeTrains < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Rails/NotNullColumn
  # rubocop:disable Migration/AddReference
  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    add_reference :merge_trains, :target_project, null: false, index: true, foreign_key: { on_delete: :cascade, to_table: :projects }, type: :integer
    add_column :merge_trains, :target_branch, :text, null: false
  end
  # rubocop:enable Migration/AddLimitToTextColumns
  # rubocop:enable Migration/AddReference
  # rubocop:enable Rails/NotNullColumn
end
