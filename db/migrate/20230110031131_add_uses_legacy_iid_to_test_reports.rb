# frozen_string_literal: true

class AddUsesLegacyIidToTestReports < Gitlab::Database::Migration[2.1]
  def change
    add_column :requirements_management_test_reports, :uses_legacy_iid, :boolean, null: false, default: true
  end
end
