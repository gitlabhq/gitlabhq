# frozen_string_literal: true

class RemoveNotNullConstraintFromUrlColumn < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  def up
    change_column_null :workspaces, :url, true
  end

  def down
    change_column_null :workspaces, :url, false
  end
end
