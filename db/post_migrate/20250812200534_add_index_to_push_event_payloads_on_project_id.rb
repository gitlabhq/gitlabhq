# frozen_string_literal: true

class AddIndexToPushEventPayloadsOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  INDEX_NAME = 'index_push_event_payloads_on_project_id'

  def up
    # NOTE: the index was created in https://gitlab.com/gitlab-org/gitlab/-/blob/37ba826a62b0323a613949cb8c98fc14575abff0/db/post_migrate/20250301122036_prepare_index_push_event_payloads_on_project_id.rb
    # rubocop:disable Migration/PreventIndexCreation -- Needed index for sharding key
    add_concurrent_index :push_event_payloads, :project_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :push_event_payloads, INDEX_NAME
  end
end
