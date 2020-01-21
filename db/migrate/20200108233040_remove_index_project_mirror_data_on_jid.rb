# frozen_string_literal: true

class RemoveIndexProjectMirrorDataOnJid < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :project_mirror_data, :jid
  end

  def down
    add_concurrent_index :project_mirror_data, :jid
  end
end
