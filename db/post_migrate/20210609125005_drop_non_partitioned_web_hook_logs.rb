# frozen_string_literal: true

class DropNonPartitionedWebHookLogs < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  DOWNTIME = false

  def up
    drop_nonpartitioned_archive_table(:web_hook_logs)
  end

  def down
    execute(<<~SQL)
      CREATE TABLE web_hook_logs_archived (
          id integer NOT NULL,
          web_hook_id integer NOT NULL,
          trigger character varying,
          url character varying,
          request_headers text,
          request_data text,
          response_headers text,
          response_body text,
          response_status character varying,
          execution_duration double precision,
          internal_error_message character varying,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      ALTER TABLE ONLY web_hook_logs_archived ADD CONSTRAINT web_hook_logs_archived_pkey PRIMARY KEY (id);

      CREATE INDEX index_web_hook_logs_on_created_at_and_web_hook_id ON web_hook_logs_archived USING btree (created_at, web_hook_id);
      CREATE INDEX index_web_hook_logs_on_web_hook_id ON web_hook_logs_archived USING btree (web_hook_id);

      ALTER TABLE ONLY web_hook_logs_archived ADD CONSTRAINT fk_rails_666826e111 FOREIGN KEY (web_hook_id) REFERENCES web_hooks(id) ON DELETE CASCADE;
    SQL

    with_lock_retries do
      create_trigger_to_sync_tables(:web_hook_logs, :web_hook_logs_archived, 'id')
    end
  end
end
