# frozen_string_literal: true

class RemoveUpdatedAtFromAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::SchemaHelpers
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  SOURCE_TABLE_NAME = 'audit_events'
  PARTITIONED_TABLE_NAME = 'audit_events_part_5fc467ac26'
  TRIGGER_FUNCTION_NAME = 'table_sync_function_2be879775d'

  def up
    with_lock_retries do
      remove_column SOURCE_TABLE_NAME, :updated_at

      create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
        <<~SQL
          IF (TG_OP = 'DELETE') THEN
            DELETE FROM #{PARTITIONED_TABLE_NAME} where id = OLD.id;
          ELSIF (TG_OP = 'UPDATE') THEN
            UPDATE #{PARTITIONED_TABLE_NAME}
            SET author_id = NEW.author_id,
              type = NEW.type,
              entity_id = NEW.entity_id,
              entity_type = NEW.entity_type,
              details = NEW.details,
              ip_address = NEW.ip_address,
              author_name = NEW.author_name,
              entity_path = NEW.entity_path,
              target_details = NEW.target_details,
              created_at = NEW.created_at
            WHERE #{PARTITIONED_TABLE_NAME}.id = NEW.id;
          ELSIF (TG_OP = 'INSERT') THEN
            INSERT INTO #{PARTITIONED_TABLE_NAME} (id,
              author_id,
              type,
              entity_id,
              entity_type,
              details,
              ip_address,
              author_name,
              entity_path,
              target_details,
              created_at)
            VALUES (NEW.id,
              NEW.author_id,
              NEW.type,
              NEW.entity_id,
              NEW.entity_type,
              NEW.details,
              NEW.ip_address,
              NEW.author_name,
              NEW.entity_path,
              NEW.target_details,
              NEW.created_at);
          END IF;
          RETURN NULL;
        SQL
      end

      remove_column PARTITIONED_TABLE_NAME, :updated_at
    end
  end

  def down
    with_lock_retries do
      add_column SOURCE_TABLE_NAME, :updated_at, :datetime # rubocop:disable Migration/Datetime
      add_column PARTITIONED_TABLE_NAME, :updated_at, :datetime # rubocop:disable Migration/Datetime

      create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
        <<~SQL
          IF (TG_OP = 'DELETE') THEN
            DELETE FROM #{PARTITIONED_TABLE_NAME} where id = OLD.id;
          ELSIF (TG_OP = 'UPDATE') THEN
            UPDATE #{PARTITIONED_TABLE_NAME}
            SET author_id = NEW.author_id,
              type = NEW.type,
              entity_id = NEW.entity_id,
              entity_type = NEW.entity_type,
              details = NEW.details,
              updated_at = NEW.updated_at,
              ip_address = NEW.ip_address,
              author_name = NEW.author_name,
              entity_path = NEW.entity_path,
              target_details = NEW.target_details,
              created_at = NEW.created_at
            WHERE #{PARTITIONED_TABLE_NAME}.id = NEW.id;
          ELSIF (TG_OP = 'INSERT') THEN
            INSERT INTO #{PARTITIONED_TABLE_NAME} (id,
              author_id,
              type,
              entity_id,
              entity_type,
              details,
              updated_at,
              ip_address,
              author_name,
              entity_path,
              target_details,
              created_at)
            VALUES (NEW.id,
              NEW.author_id,
              NEW.type,
              NEW.entity_id,
              NEW.entity_type,
              NEW.details,
              NEW.updated_at,
              NEW.ip_address,
              NEW.author_name,
              NEW.entity_path,
              NEW.target_details,
              NEW.created_at);
          END IF;
          RETURN NULL;
        SQL
      end
    end
  end
end
