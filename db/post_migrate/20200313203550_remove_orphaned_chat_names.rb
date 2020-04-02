# frozen_string_literal: true

class RemoveOrphanedChatNames < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute("DELETE FROM chat_names WHERE service_id NOT IN(SELECT id FROM services WHERE services.type = 'chat')")
  end

  def down
    say 'Orphaned user chat names were removed as a part of this migration and are non-recoverable'
  end
end
