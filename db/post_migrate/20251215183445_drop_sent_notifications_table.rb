# frozen_string_literal: true

class DropSentNotificationsTable < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def up
    drop_table :sent_notifications
  end

  def down
    execute(<<~SQL)
      CREATE TABLE sent_notifications (
        project_id bigint,
        noteable_id bigint,
        noteable_type character varying,
        recipient_id bigint,
        commit_id character varying,
        reply_key character varying NOT NULL,
        in_reply_to_discussion_id character varying,
        id bigint DEFAULT nextval('sent_notifications_id_seq'::regclass) NOT NULL,
        issue_email_participant_id bigint,
        created_at timestamp with time zone NOT NULL,
        namespace_id bigint NOT NULL
      );

      ALTER TABLE ONLY sent_notifications
        ADD CONSTRAINT sent_notifications_pkey PRIMARY KEY (id);

      CREATE INDEX index_sent_notifications_on_issue_email_participant_id ON sent_notifications
        USING btree (issue_email_participant_id);
      CREATE INDEX index_sent_notifications_on_noteable_type_noteable_id_and_id ON sent_notifications
        USING btree (noteable_id, id) WHERE ((noteable_type)::text = 'Issue'::text);
    SQL
  end
end
