# frozen_string_literal: true

class AddTextLimitToAuditEventTargetDetails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :audit_events, :target_details, 5_500
  end

  def down
    remove_text_limit :audit_events, :target_details
  end
end
