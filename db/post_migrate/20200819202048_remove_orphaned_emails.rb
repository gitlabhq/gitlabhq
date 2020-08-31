# frozen_string_literal: true

class RemoveOrphanedEmails < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute <<~SQL
      DELETE FROM emails
        WHERE not exists (
          SELECT 1 FROM users WHERE users.id = emails.user_id
        );
    SQL

    execute 'DELETE FROM emails WHERE user_id IS NULL;'
  end

  def down
    # no-op
  end
end
