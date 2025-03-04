# frozen_string_literal: true

class PrepareIndexPushEventPayloadsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_push_event_payloads_on_project_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- needed for sharding key index
    prepare_async_index :push_event_payloads, :project_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index :push_event_payloads, INDEX_NAME
  end
end
