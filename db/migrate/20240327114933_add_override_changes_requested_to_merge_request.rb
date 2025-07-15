# frozen_string_literal: true

class AddOverrideChangesRequestedToMergeRequest < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :merge_requests, :override_requested_changes, :boolean, default: false, null: false
    # rubocop:enable Migration/PreventAddingColumns
  end
end
