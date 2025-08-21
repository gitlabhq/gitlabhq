# frozen_string_literal: true

class SetPartitionedSentNotificationsSharedSequence < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def up
    execute(<<-SQL)
      ALTER TABLE p_sent_notifications
        ALTER COLUMN id SET DEFAULT nextval('sent_notifications_id_seq'::regclass);
    SQL
  end

  def down
    execute(<<-SQL)
      ALTER TABLE p_sent_notifications
        ALTER COLUMN id SET DEFAULT nextval('p_sent_notifications_id_seq'::regclass);
    SQL
  end
end
