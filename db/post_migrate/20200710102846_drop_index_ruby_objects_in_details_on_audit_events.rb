# frozen_string_literal: true

class DropIndexRubyObjectsInDetailsOnAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_audit_events_on_ruby_object_in_details'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(:audit_events, INDEX_NAME)
  end

  def down
    add_concurrent_index(:audit_events, :id, where: "details ~~ '%ruby/object%'", name: INDEX_NAME)
  end
end
