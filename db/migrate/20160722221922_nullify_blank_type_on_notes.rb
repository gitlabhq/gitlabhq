class NullifyBlankTypeOnNotes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute "UPDATE notes SET type = NULL WHERE type = ''"
  end
end
