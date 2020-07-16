# frozen_string_literal: true

class AddTextLimitOnEntityPathToAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :audit_events, :entity_path, 5_500
  end

  def down
    remove_text_limit :audit_events, :entity_path
  end
end
