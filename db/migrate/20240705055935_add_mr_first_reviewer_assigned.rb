# frozen_string_literal: true

class AddMrFirstReviewerAssigned < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :merge_request_metrics, :reviewer_first_assigned_at, :datetime_with_timezone
    # rubocop:enable Migration/PreventAddingColumns
  end
end
