# frozen_string_literal: true

class AddTextLimitToAuditEventTargetType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false
  SOURCE_TABLE_NAME = 'audit_events'
  PARTITIONED_TABLE_NAME = 'audit_events_part_5fc467ac26'

  disable_ddl_transaction!

  def up
    add_text_limit(SOURCE_TABLE_NAME, :target_type, 255)
    add_text_limit(PARTITIONED_TABLE_NAME, :target_type, 255)
  end

  def down
    remove_text_limit(SOURCE_TABLE_NAME, :target_type)
    remove_text_limit(PARTITIONED_TABLE_NAME, :target_type)
  end
end
