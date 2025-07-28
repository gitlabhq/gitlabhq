# frozen_string_literal: true

class TruncateOutOfSyncGroupPushRulesData < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    truncate_tables!('group_push_rules')
  end

  def down
    # no-op
  end
end
