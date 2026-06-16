# frozen_string_literal: true

class AddRolesToTargetedMessages < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    add_column :targeted_messages, :roles, :smallint, array: true, default: [], null: false
  end
end
