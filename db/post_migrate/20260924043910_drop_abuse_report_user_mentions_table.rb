# frozen_string_literal: true

class DropAbuseReportUserMentionsTable < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.5'

  TABLE_NAME = :abuse_report_user_mentions

  def up
    drop_table TABLE_NAME, if_exists: true
  end

  # No foreign keys are restored here. Each one is re-added by the `down` of
  # the migration that removed it, so adding them here too would leave a
  # rollback of this migration alone in the wrong state.
  def down
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.bigint :abuse_report_id, null: false
      t.bigint :note_id, null: false
      t.bigint :mentioned_users_ids, array: true
      t.bigint :mentioned_projects_ids, array: true
      t.bigint :mentioned_groups_ids, array: true
      t.bigint :organization_id

      t.check_constraint 'organization_id IS NOT NULL', name: 'check_f0d6e86b14'
    end

    add_concurrent_index TABLE_NAME, [:abuse_report_id, :note_id], unique: true,
      name: 'index_abuse_report_user_mentions_on_abuse_report_id_and_note_id'
    add_concurrent_index TABLE_NAME, :note_id,
      name: 'index_abuse_report_user_mentions_on_note_id'
    add_concurrent_index TABLE_NAME, :organization_id,
      name: 'index_abuse_report_user_mentions_on_organization_id'
  end
end
