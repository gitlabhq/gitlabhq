# frozen_string_literal: true

class ChangeUpcomingReconciliationsOrganizationIdDefault < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  DEFAULT_ORGANIZATION_ID = 1

  def up
    change_column_default('upcoming_reconciliations', 'organization_id', nil)
  end

  def down
    change_column_default('upcoming_reconciliations', 'organization_id', DEFAULT_ORGANIZATION_ID)
  end
end
