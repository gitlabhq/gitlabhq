# frozen_string_literal: true

class AddMultiColumnNotNullConstraintToIssueTrackerData < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  def up
    # no-op
  end

  def down
    # no-op
  end
end
