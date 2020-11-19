# frozen_string_literal: true

class AddIndexActiveBillableUsersToUser < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'active_billable_users'
  HUMAN_TYPE = 'NULL'
  HUMAN_SVC_BOT_TYPES = "#{HUMAN_TYPE}, 6, 4"
  BOT_TYPES = '2,6,1,3,7,8'

  disable_ddl_transaction!

  def up
    add_concurrent_index :users, :id, name: INDEX_NAME, where: "(state = 'active' AND (user_type is #{HUMAN_TYPE} or user_type in (#{HUMAN_SVC_BOT_TYPES}))) and ((users.user_type IS #{HUMAN_TYPE}) OR (users.user_type <> ALL ('{#{BOT_TYPES}}')))"
  end

  def down
    remove_concurrent_index_by_name(:users, INDEX_NAME)
  end
end
