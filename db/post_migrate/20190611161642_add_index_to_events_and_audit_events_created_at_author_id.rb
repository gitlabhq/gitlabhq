# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexToEventsAndAuditEventsCreatedAtAuthorId < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'analytics_index_%s_on_created_at_and_author_id'
  EVENTS_INDEX_NAME = (INDEX_NAME % 'events')
  AUDIT_EVENTS_INDEX_NAME = (INDEX_NAME % 'audit_events')

  disable_ddl_transaction!

  def up
    add_concurrent_index :events, [:created_at, :author_id], name: EVENTS_INDEX_NAME
    add_concurrent_index :audit_events, [:created_at, :author_id], name: AUDIT_EVENTS_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :events, EVENTS_INDEX_NAME
    remove_concurrent_index_by_name :audit_events, AUDIT_EVENTS_INDEX_NAME
  end
end
