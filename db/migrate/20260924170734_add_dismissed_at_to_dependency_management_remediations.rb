# frozen_string_literal: true

class AddDismissedAtToDependencyManagementRemediations < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :dependency_management_remediations, :dismissed_at, :datetime_with_timezone
  end
end
