# frozen_string_literal: true

class AddTextLimitToGroupImportStates < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :group_import_states, :jid, 100
    add_text_limit :group_import_states, :last_error, 255
  end

  def down
    remove_text_limit :group_import_states, :jid
    remove_text_limit :group_import_states, :last_error
  end
end
