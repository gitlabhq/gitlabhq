# frozen_string_literal: true

class CreateAbuseReportUserMentions < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    create_table :abuse_report_user_mentions do |t|
      t.bigint :abuse_report_id, null: false
      t.bigint :note_id, null: false
      t.bigint :mentioned_users_ids, array: true, default: nil
      t.bigint :mentioned_projects_ids, array: true, default: nil
      t.bigint :mentioned_groups_ids, array: true, default: nil

      t.index :note_id
      t.index [:abuse_report_id, :note_id],
        unique: true,
        name: :index_abuse_report_user_mentions_on_abuse_report_id_and_note_id
    end
  end

  def down
    drop_table :abuse_report_user_mentions, if_exists: true
  end
end
