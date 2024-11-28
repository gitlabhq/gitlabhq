# frozen_string_literal: true

class AddRetargetedToMergeRequests < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :merge_requests, :retargeted, :boolean, default: false, null: false
    # rubocop:enable Migration/PreventAddingColumns
  end
end
