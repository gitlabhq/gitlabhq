# frozen_string_literal: true

class ChangeColumnNullTestReportRequirement < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  TARGET_TABLE = :requirements_management_test_reports

  def up
    with_lock_retries do
      change_column_null TARGET_TABLE, :requirement_id, true
    end
  end

  def down
    # no-op as it's difficult to revert
  end
end
