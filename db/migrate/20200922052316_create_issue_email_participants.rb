# frozen_string_literal: true

class CreateIssueEmailParticipants < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:issue_email_participants)
      with_lock_retries do
        create_table :issue_email_participants do |t|
          t.references :issue, index: false, null: false, foreign_key: { on_delete: :cascade }
          t.datetime_with_timezone :created_at, null: false
          t.datetime_with_timezone :updated_at, null: false
          t.text :email, null: false

          t.index [:issue_id, :email], unique: true
        end
      end

      add_text_limit(:issue_email_participants, :email, 255)
    end
  end

  def down
    with_lock_retries do
      drop_table :issue_email_participants
    end
  end
end
