# frozen_string_literal: true

class DropNullConstraintOnGroupImportStateJid < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    change_column_null :group_import_states, :jid, true
  end

  def down
    # No-op -- null values could have been added after this this constraint was removed.
  end
end
