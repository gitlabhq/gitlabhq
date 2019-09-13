# frozen_string_literal: true

class AddTargetProjectIdToMergeTrains < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    # rubocop:disable Rails/NotNullColumn, Migration/AddReference
    add_reference :merge_trains, :target_project, null: false, index: true, foreign_key: { on_delete: :cascade, to_table: :projects }, type: :integer
    add_column :merge_trains, :target_branch, :text, null: false
    # rubocop:enable Rails/NotNullColumn, Migration/AddReference
  end
end
