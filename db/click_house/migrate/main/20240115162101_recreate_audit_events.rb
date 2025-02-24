# frozen_string_literal: true

class RecreateAuditEvents < ClickHouse::Migration
  def up
    # No-op due to a CH version incompatibility issue: https://gitlab.com/gitlab-org/gitlab/-/issues/518619
    # Also the table was never used in production and it was removed with 20240115122100_drop_audit_events.rb
  end

  def down
    # no-op
  end
end
