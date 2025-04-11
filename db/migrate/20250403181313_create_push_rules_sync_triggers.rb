# frozen_string_literal: true

class CreatePushRulesSyncTriggers < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::SchemaHelpers

  disable_ddl_transaction!
  milestone '17.11'

  SYNC_TRIGGER_NAME = 'trigger_sync_organization_push_rules_insert_update'
  DELETE_TRIGGER_NAME = 'trigger_sync_organization_push_rules_delete'

  SYNC_FUNCTION_NAME = 'sync_organization_push_rules_on_insert_update'
  DELETE_FUNCTION_NAME = 'sync_organization_push_rules_on_delete'

  def up
    # We need to populate organization_push_rules when push_rules are created or updated
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{SYNC_FUNCTION_NAME}()
        RETURNS TRIGGER
        LANGUAGE plpgsql
      AS $$
       BEGIN
          IF (NEW.organization_id IS NOT NULL AND NEW.is_sample = TRUE) THEN
            INSERT INTO organization_push_rules (
              organization_id,
              max_file_size,
              member_check,
              prevent_secrets,
              reject_unsigned_commits,
              commit_committer_check,
              deny_delete_tag,
              reject_non_dco_commits,
              commit_committer_name_check,
              commit_message_regex,
              branch_name_regex,
              commit_message_negative_regex,
              author_email_regex,
              file_name_regex,
              created_at,
              updated_at
            ) VALUES (
              NEW.organization_id,
              NEW.max_file_size,
              NEW.member_check,
              NEW.prevent_secrets,
              NEW.reject_unsigned_commits,
              NEW.commit_committer_check,
              NEW.deny_delete_tag,
              NEW.reject_non_dco_commits,
              NEW.commit_committer_name_check,
              NEW.commit_message_regex,
              NEW.branch_name_regex,
              NEW.commit_message_negative_regex,
              NEW.author_email_regex,
              NEW.file_name_regex,
              NEW.created_at,
              NEW.updated_at
            )
            ON CONFLICT (organization_id) DO UPDATE SET
              max_file_size = NEW.max_file_size,
              member_check = NEW.member_check,
              prevent_secrets = NEW.prevent_secrets,
              reject_unsigned_commits = NEW.reject_unsigned_commits,
              commit_committer_check = NEW.commit_committer_check,
              deny_delete_tag = NEW.deny_delete_tag,
              reject_non_dco_commits = NEW.reject_non_dco_commits,
              commit_committer_name_check = NEW.commit_committer_name_check,
              commit_message_regex = NEW.commit_message_regex,
              branch_name_regex = NEW.branch_name_regex,
              commit_message_negative_regex = NEW.commit_message_negative_regex,
              author_email_regex = NEW.author_email_regex,
              file_name_regex = NEW.file_name_regex,
              updated_at = NEW.updated_at;
          END IF;
         RETURN NEW;
        END;
       $$
    SQL

    drop_trigger(:push_rules, SYNC_TRIGGER_NAME)

    # Create the trigger for INSERT and UPDATE operations
    execute(<<~SQL)
      CREATE TRIGGER #{SYNC_TRIGGER_NAME}
      AFTER INSERT OR UPDATE ON push_rules
      FOR EACH ROW
      EXECUTE FUNCTION #{SYNC_FUNCTION_NAME}();
    SQL

    # Create a trigger function for DELETE operations
    # Delete corresponding organization_push_rule when push_rule is deleted
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{DELETE_FUNCTION_NAME}()
        RETURNS TRIGGER
        LANGUAGE plpgsql
      AS $$
        BEGIN
          IF (OLD.organization_id IS NOT NULL AND OLD.is_sample = true) THEN
            DELETE FROM organization_push_rules WHERE organization_id = OLD.organization_id;
          END IF;
          RETURN OLD;
        END;
      $$;
    SQL

    drop_trigger(:push_rules, DELETE_TRIGGER_NAME)

    # Create the trigger for DELETE operations
    execute(<<~SQL)
      CREATE TRIGGER #{DELETE_TRIGGER_NAME}
      BEFORE DELETE ON push_rules
      FOR EACH ROW
      EXECUTE FUNCTION #{DELETE_FUNCTION_NAME}();
    SQL
  end

  def down
    drop_trigger(:push_rules, SYNC_TRIGGER_NAME)
    drop_trigger(:push_rules, DELETE_TRIGGER_NAME)
    drop_function(SYNC_FUNCTION_NAME)
    drop_function(DELETE_FUNCTION_NAME)
  end
end
