# frozen_string_literal: true

class AddBroadcastTypeToBroadcastMessage < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  BROADCAST_MESSAGE_BANNER_TYPE = 1

  disable_ddl_transaction!

  def up
    add_column_with_default(:broadcast_messages, :broadcast_type, :smallint, default: BROADCAST_MESSAGE_BANNER_TYPE) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:broadcast_messages, :broadcast_type)
  end
end
