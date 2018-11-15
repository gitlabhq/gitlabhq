# frozen_string_literal: true
class AddIndexForStuckMrQuery < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, [:id, :merge_jid], where: "merge_jid IS NOT NULL and state = 'locked'"
  end

  def down
    remove_concurrent_index :merge_requests, [:id, :merge_jid], where: "merge_jid IS NOT NULL and state = 'locked'"
  end
end
