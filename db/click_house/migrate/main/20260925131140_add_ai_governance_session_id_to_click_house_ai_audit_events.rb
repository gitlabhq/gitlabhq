# frozen_string_literal: true

class AddAiGovernanceSessionIdToClickHouseAiAuditEvents < ClickHouse::Migration
  def up
    # No-op because the migration failed on gstg-cny with CANNOT_ASSIGN_ALTER and blocked
    # auto-deploy: https://gitlab.com/gitlab-com/gl-infra/production/-/work_items/23053
  end

  def down
    # no-op
  end
end
