# frozen_string_literal: true

class CreatePartitionedByListSentNotificationsTable < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  disable_ddl_transaction!
  milestone '18.3'

  TABLE_NAME = 'sent_notifications'
  PARTITIONED_TABLE_NAME = 'p_sent_notifications'
  PARTITIONED_TABLE_PK = %w[id partition]
  FUNCTION_NAME = 'sync_to_p_sent_notifications_table'
  TRIGGER_NAME = 'sync_sent_notifications_to_part'

  def up
    create_partitioned_table

    add_sync_trigger
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_NAME)
    drop_function(FUNCTION_NAME)
    drop_table :p_sent_notifications, if_exists: true
  end

  private

  def create_partitioned_table
    options = 'PARTITION BY LIST (partition)'
    create_table PARTITIONED_TABLE_NAME, primary_key: PARTITIONED_TABLE_PK, options: options, if_not_exists: true do |t|
      t.bigserial :id, null: false
      t.bigint :project_id
      t.bigint :noteable_id
      t.bigint :recipient_id
      t.references :issue_email_participant, type: :bigint, foreign_key: { on_delete: :cascade }, index: false
      t.bigint :namespace_id, null: false
      t.datetime_with_timezone :created_at, null: false
      t.integer :partition, null: false, default: 1
      t.text :noteable_type, limit: 255
      t.text :commit_id, limit: 255
      t.text :reply_key, null: false, limit: 255
      t.text :in_reply_to_discussion_id, limit: 255

      t.index [:reply_key, :partition], unique: true, name: 'index_p_sent_notifications_on_reply_key_partition_unique'
      t.index :issue_email_participant_id, name: 'index_p_sent_notifications_on_issue_email_participant_id'
      t.index :namespace_id, name: 'index_p_sent_notifications_on_namespace_id'
      t.index [:noteable_id, :id], name: 'index_p_sent_notifications_on_noteable_type_noteable_id_and_id',
        where: "noteable_type = 'Issue'"
    end
  end

  def add_sync_trigger
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
