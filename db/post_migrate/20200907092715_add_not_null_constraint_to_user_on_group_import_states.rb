# frozen_string_literal: true

class AddNotNullConstraintToUserOnGroupImportStates < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_not_null_constraint :group_import_states, :user_id, validate: false
  end

  def down
    remove_not_null_constraint :group_import_states, :user_id
  end
end
