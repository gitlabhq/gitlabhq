# frozen_string_literal: true

class AddByteaShaColumnsToMergeRequestDiffs < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '19.2'
  disable_ddl_transaction!

  TABLE              = :merge_request_diffs
  INSERT_FUNCTION    = :merge_request_diffs_sync_bytea_sha_on_insert
  UPDATE_FUNCTION    = :merge_request_diffs_sync_bytea_sha_on_update
  INSERT_TRIGGER     = :merge_request_diffs_sync_bytea_sha_on_insert
  UPDATE_TRIGGER     = :merge_request_diffs_sync_bytea_sha_on_update
  WATCHED_COLUMNS    = %w[
    base_commit_sha base_commit_sha_bytea
    start_commit_sha start_commit_sha_bytea
    head_commit_sha head_commit_sha_bytea
  ].freeze

  def up
    with_lock_retries do
      add_column TABLE, :base_commit_sha_bytea,  :binary, if_not_exists: true
      add_column TABLE, :start_commit_sha_bytea, :binary, if_not_exists: true
      add_column TABLE, :head_commit_sha_bytea,  :binary, if_not_exists: true
    end

    create_trigger_function(INSERT_FUNCTION, replace: true) do
      <<~SQL
        IF NEW.base_commit_sha IS NOT NULL THEN
          NEW.base_commit_sha_bytea := decode(NEW.base_commit_sha, 'hex');
        ELSIF NEW.base_commit_sha_bytea IS NOT NULL THEN
          NEW.base_commit_sha := encode(NEW.base_commit_sha_bytea, 'hex');
        END IF;

        IF NEW.start_commit_sha IS NOT NULL THEN
          NEW.start_commit_sha_bytea := decode(NEW.start_commit_sha, 'hex');
        ELSIF NEW.start_commit_sha_bytea IS NOT NULL THEN
          NEW.start_commit_sha := encode(NEW.start_commit_sha_bytea, 'hex');
        END IF;

        IF NEW.head_commit_sha IS NOT NULL THEN
          NEW.head_commit_sha_bytea := decode(NEW.head_commit_sha, 'hex');
        ELSIF NEW.head_commit_sha_bytea IS NOT NULL THEN
          NEW.head_commit_sha := encode(NEW.head_commit_sha_bytea, 'hex');
        END IF;

        RETURN NEW;
      SQL
    end

    create_trigger_function(UPDATE_FUNCTION, replace: true) do
      <<~SQL
        IF NEW.base_commit_sha IS DISTINCT FROM OLD.base_commit_sha THEN
          NEW.base_commit_sha_bytea := decode(NEW.base_commit_sha, 'hex');
        ELSIF NEW.base_commit_sha_bytea IS DISTINCT FROM OLD.base_commit_sha_bytea THEN
          NEW.base_commit_sha := encode(NEW.base_commit_sha_bytea, 'hex');
        END IF;

        IF NEW.start_commit_sha IS DISTINCT FROM OLD.start_commit_sha THEN
          NEW.start_commit_sha_bytea := decode(NEW.start_commit_sha, 'hex');
        ELSIF NEW.start_commit_sha_bytea IS DISTINCT FROM OLD.start_commit_sha_bytea THEN
          NEW.start_commit_sha := encode(NEW.start_commit_sha_bytea, 'hex');
        END IF;

        IF NEW.head_commit_sha IS DISTINCT FROM OLD.head_commit_sha THEN
          NEW.head_commit_sha_bytea := decode(NEW.head_commit_sha, 'hex');
        ELSIF NEW.head_commit_sha_bytea IS DISTINCT FROM OLD.head_commit_sha_bytea THEN
          NEW.head_commit_sha := encode(NEW.head_commit_sha_bytea, 'hex');
        END IF;

        RETURN NEW;
      SQL
    end

    with_lock_retries do
      execute(<<~SQL) unless trigger_exists?(TABLE, INSERT_TRIGGER)
        CREATE TRIGGER #{INSERT_TRIGGER}
          BEFORE INSERT ON #{TABLE}
          FOR EACH ROW
          EXECUTE FUNCTION #{INSERT_FUNCTION}();
      SQL

      execute(<<~SQL) unless trigger_exists?(TABLE, UPDATE_TRIGGER)
        CREATE TRIGGER #{UPDATE_TRIGGER}
          BEFORE UPDATE OF #{WATCHED_COLUMNS.join(', ')} ON #{TABLE}
          FOR EACH ROW
          EXECUTE FUNCTION #{UPDATE_FUNCTION}();
      SQL
    end
  end

  def down
    # rubocop: disable Migration/WithLockRetriesDisallowedMethod -- Lock retries are recommended for trigger drops on high-traffic tables
    with_lock_retries do
      drop_trigger(TABLE, UPDATE_TRIGGER)
      drop_trigger(TABLE, INSERT_TRIGGER)
    end
    # rubocop: enable Migration/WithLockRetriesDisallowedMethod

    drop_function(UPDATE_FUNCTION)
    drop_function(INSERT_FUNCTION)

    with_lock_retries do
      remove_column TABLE, :head_commit_sha_bytea,  if_exists: true
      remove_column TABLE, :start_commit_sha_bytea, if_exists: true
      remove_column TABLE, :base_commit_sha_bytea,  if_exists: true
    end
  end
end
