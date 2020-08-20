# frozen_string_literal: true

class RemoveIndexChatNameServiceId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :chat_names, :service_id
  end

  def down
    add_concurrent_index :chat_names, :service_id
  end
end
