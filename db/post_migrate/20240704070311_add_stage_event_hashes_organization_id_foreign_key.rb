# frozen_string_literal: true

class AddStageEventHashesOrganizationIdForeignKey < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.2'

  def up
    add_concurrent_foreign_key :analytics_cycle_analytics_stage_event_hashes, :organizations, column: :organization_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :analytics_cycle_analytics_stage_event_hashes, column: :organization_id
  end
end
