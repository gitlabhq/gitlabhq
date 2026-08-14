# frozen_string_literal: true

class DropAbuseReportUserMentionsTable < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  TABLE_NAME = :abuse_report_user_mentions

  def up
    drop_table TABLE_NAME, if_exists: true
  end

  def down
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.bigint :abuse_report_id, null: false
      t.bigint :note_id, null: false
      t.bigint :mentioned_users_ids, array: true
      t.bigint :mentioned_projects_ids, array: true
      t.bigint :mentioned_groups_ids, array: true
      t.bigint :organization_id

      t.index [:abuse_report_id, :note_id], unique: true,
        name: 'index_abuse_report_user_mentions_on_abuse_report_id_and_note_id'
      t.index :note_id, name: 'index_abuse_report_user_mentions_on_note_id'
      t.index :organization_id, name: 'index_abuse_report_user_mentions_on_organization_id'
    end

    add_not_null_constraint TABLE_NAME, :organization_id
  end
end
