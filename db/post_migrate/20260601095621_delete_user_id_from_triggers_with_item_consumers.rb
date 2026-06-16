# frozen_string_literal: true

class DeleteUserIdFromTriggersWithItemConsumers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    flow_triggers = define_batchable_model('ai_flow_triggers')
      .where.not(user_id: nil)
      .where.not(ai_catalog_item_consumer_id: nil)

    flow_triggers.each_batch(of: 1000) do |batch|
      batch.update_all(user_id: nil)
    end
  end

  def down
    # no-op
  end
end
