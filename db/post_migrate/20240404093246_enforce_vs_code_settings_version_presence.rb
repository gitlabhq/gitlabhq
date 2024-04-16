# frozen_string_literal: true

class EnforceVsCodeSettingsVersionPresence < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.11'

  def up
    add_not_null_constraint :vs_code_settings, :version
  end

  def down
    remove_not_null_constraint :vs_code_settings, :version
  end
end
