# frozen_string_literal: true

class DropProjectPushRulesSyncTriggers < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  disable_ddl_transaction!
  milestone '19.1'

  INSERT_UPDATE_TRIGGER_NAME = 'trigger_sync_project_push_rules_insert_update'
  INSERT_UPDATE_FUNCTION_NAME = 'sync_project_push_rules_on_insert_update'
  DELETE_TRIGGER_NAME = 'trigger_sync_project_push_rules_delete'
  DELETE_FUNCTION_NAME = 'sync_project_push_rules_on_delete'

  def up
    drop_trigger(:push_rules, INSERT_UPDATE_TRIGGER_NAME)
    drop_trigger(:push_rules, DELETE_TRIGGER_NAME)
    drop_function(INSERT_UPDATE_FUNCTION_NAME)
    drop_function(DELETE_FUNCTION_NAME)
  end

  def down
    execute(<<-SQL)
CREATE OR REPLACE FUNCTION #{INSERT_UPDATE_FUNCTION_NAME}() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
 BEGIN
    IF (NEW.project_id IS NOT NULL) THEN
      IF EXISTS (SELECT 1 FROM project_push_rules WHERE project_id = NEW.project_id) THEN
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
        WHERE project_id = NEW.project_id;
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
          nextval(pg_get_serial_sequence('project_push_rules', 'id')),
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
          updated_at = EXCLUDED.updated_at;
      END IF;
    END IF;
   RETURN NEW;
  END;
 $$;
    SQL

    execute(<<-SQL)
CREATE OR REPLACE FUNCTION #{DELETE_FUNCTION_NAME}() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
 BEGIN
    IF (OLD.project_id IS NOT NULL) THEN
      DELETE FROM project_push_rules WHERE project_id = OLD.project_id;
    END IF;
   RETURN OLD;
  END;
 $$;
    SQL

    create_trigger(:push_rules, INSERT_UPDATE_TRIGGER_NAME, INSERT_UPDATE_FUNCTION_NAME,
      fires: 'AFTER INSERT OR UPDATE', replace: true)

    create_trigger(:push_rules, DELETE_TRIGGER_NAME, DELETE_FUNCTION_NAME,
      fires: 'AFTER DELETE', replace: true)
  end
end
