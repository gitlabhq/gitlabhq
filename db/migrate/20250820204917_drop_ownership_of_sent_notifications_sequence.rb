# frozen_string_literal: true

class DropOwnershipOfSentNotificationsSequence < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def up
    execute(<<-SQL)
      ALTER SEQUENCE sent_notifications_id_seq OWNED BY NONE;
    SQL
  end

  def down
    execute(<<-SQL)
      ALTER SEQUENCE sent_notifications_id_seq OWNED BY sent_notifications.id;
    SQL
  end
end
