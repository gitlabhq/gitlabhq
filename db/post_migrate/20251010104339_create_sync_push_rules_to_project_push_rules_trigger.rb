# frozen_string_literal: true

class CreateSyncPushRulesToProjectPushRulesTrigger < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  disable_ddl_transaction!
  milestone '18.6'

  SYNC_TRIGGER_NAME = 'trigger_sync_project_push_rules_insert_update'
  SYNC_FUNCTION_NAME = 'sync_project_push_rules_on_insert_update'
  DELETE_TRIGGER_NAME = 'trigger_sync_project_push_rules_delete'
  DELETE_FUNCTION_NAME = 'sync_project_push_rules_on_delete'

  def up
    with_lock_retries do
      execute(<<~SQL)
        CREATE OR REPLACE FUNCTION #{SYNC_FUNCTION_NAME}()
          RETURNS TRIGGER
          LANGUAGE plpgsql
        AS $$
         BEGIN
            IF (NEW.project_id IS NOT NULL) THEN
              IF EXISTS (SELECT 1 FROM project_push_rules WHERE id = NEW.id) THEN
                UPDATE project_push_rules SET
                  max_file_size = NEW.max_file_size,
                  member_check = NEW.member_check,
                  prevent_secrets = NEW.prevent_secrets,
                  commit_committer_name_check = NEW.commit_committer_name_check,
                  deny_delete_tag = NEW.deny_delete_tag,
                  reject_unsigned_commits = NEW.reject_unsigned_commits,
                  commit_committer_check = NEW.commit_committer_check,
                  reject_non_dco_commits = NEW.reject_non_dco_commits,
                  commit_message_regex = NEW.commit_message_regex,
                  branch_name_regex = NEW.branch_name_regex,
                  commit_message_negative_regex = NEW.commit_message_negative_regex,
                  author_email_regex = NEW.author_email_regex,
                  file_name_regex = NEW.file_name_regex,
                  updated_at = NEW.updated_at
                WHERE id = NEW.id;
              ELSE
                INSERT INTO project_push_rules (
                  id,
                  project_id,
                  max_file_size,
                  member_check,
                  prevent_secrets,
                  commit_committer_name_check,
                  deny_delete_tag,
                  reject_unsigned_commits,
                  commit_committer_check,
                  reject_non_dco_commits,
                  commit_message_regex,
                  branch_name_regex,
                  commit_message_negative_regex,
                  author_email_regex,
                  file_name_regex,
                  created_at,
                  updated_at
                ) VALUES (
                  NEW.id,
                  NEW.project_id,
                  NEW.max_file_size,
                  NEW.member_check,
                  NEW.prevent_secrets,
                  NEW.commit_committer_name_check,
                  NEW.deny_delete_tag,
                  NEW.reject_unsigned_commits,
                  NEW.commit_committer_check,
                  NEW.reject_non_dco_commits,
                  NEW.commit_message_regex,
                  NEW.branch_name_regex,
                  NEW.commit_message_negative_regex,
                  NEW.author_email_regex,
                  NEW.file_name_regex,
                  NEW.created_at,
                  NEW.updated_at
                )
                ON CONFLICT (project_id) DO UPDATE SET
                  id = EXCLUDED.id,
                  max_file_size = EXCLUDED.max_file_size,
                  member_check = EXCLUDED.member_check,
                  prevent_secrets = EXCLUDED.prevent_secrets,
                  commit_committer_name_check = EXCLUDED.commit_committer_name_check,
                  deny_delete_tag = EXCLUDED.deny_delete_tag,
                  reject_unsigned_commits = EXCLUDED.reject_unsigned_commits,
                  commit_committer_check = EXCLUDED.commit_committer_check,
                  reject_non_dco_commits = EXCLUDED.reject_non_dco_commits,
                  commit_message_regex = EXCLUDED.commit_message_regex,
                  branch_name_regex = EXCLUDED.branch_name_regex,
                  commit_message_negative_regex = EXCLUDED.commit_message_negative_regex,
                  author_email_regex = EXCLUDED.author_email_regex,
                  file_name_regex = EXCLUDED.file_name_regex,
                  updated_at = EXCLUDED.updated_at
                WHERE NOT EXISTS (SELECT 1 FROM project_push_rules WHERE id = EXCLUDED.id AND project_id != EXCLUDED.project_id);
              END IF;
            END IF;
           RETURN NEW;
          END;
         $$
      SQL
    end

    with_lock_retries do
      execute(<<~SQL)
        CREATE OR REPLACE TRIGGER #{SYNC_TRIGGER_NAME}
        AFTER INSERT OR UPDATE ON push_rules
        FOR EACH ROW
        EXECUTE FUNCTION #{SYNC_FUNCTION_NAME}();
      SQL
    end

    with_lock_retries do
      execute(<<~SQL)
        CREATE OR REPLACE FUNCTION #{DELETE_FUNCTION_NAME}()
          RETURNS TRIGGER
          LANGUAGE plpgsql
        AS $$
         BEGIN
            IF (OLD.project_id IS NOT NULL) THEN
              DELETE FROM project_push_rules WHERE project_id = OLD.project_id;
            END IF;
           RETURN OLD;
          END;
         $$
      SQL
    end

    with_lock_retries do
      execute(<<~SQL)
        CREATE OR REPLACE TRIGGER #{DELETE_TRIGGER_NAME}
        AFTER DELETE ON push_rules
        FOR EACH ROW
        EXECUTE FUNCTION #{DELETE_FUNCTION_NAME}();
      SQL
    end
  end

  def down
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- Need this here for trigger drop
    with_lock_retries do
      drop_trigger(:push_rules, SYNC_TRIGGER_NAME)
    end

    with_lock_retries do
      drop_trigger(:push_rules, DELETE_TRIGGER_NAME)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod

    drop_function(SYNC_FUNCTION_NAME)
    drop_function(DELETE_FUNCTION_NAME)
  end
end
