class NullifyBlankTypeOnNotes < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute "UPDATE notes SET type = NULL WHERE type = ''"
  end
end
