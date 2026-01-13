# frozen_string_literal: true

class DropSentNotificationsSyncTrigger < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  TABLE_NAME = 'sent_notifications'
  FUNCTION_NAME = 'sync_to_p_sent_notifications_table'
  TRIGGER_NAME = 'sync_sent_notifications_to_part'

  milestone '18.8'

  def up
    drop_trigger(TABLE_NAME, TRIGGER_NAME)
    drop_function(FUNCTION_NAME)
  end

  def down
    create_trigger_function(FUNCTION_NAME, replace: true) do
      <<~SQL
        INSERT INTO "p_sent_notifications" (
          "project_id",
          "noteable_id",
          "noteable_type",
          "recipient_id",
          "commit_id",
          "reply_key",
          "in_reply_to_discussion_id",
          "id",
          "issue_email_participant_id",
          "namespace_id",
          "created_at"
        ) VALUES (
          NEW."project_id",
          NEW."noteable_id",
          NEW."noteable_type",
          NEW."recipient_id",
          NEW."commit_id",
          NEW."reply_key",
          NEW."in_reply_to_discussion_id",
          NEW."id",
          NEW."issue_email_participant_id",
          NEW."namespace_id",
          NEW."created_at"
        );

        RETURN NEW;
      SQL
    end

    create_trigger(TABLE_NAME, TRIGGER_NAME, FUNCTION_NAME, fires: 'AFTER INSERT')
  end
end
