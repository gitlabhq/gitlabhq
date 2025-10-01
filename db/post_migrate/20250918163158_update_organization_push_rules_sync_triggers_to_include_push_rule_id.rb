# frozen_string_literal: true

class UpdateOrganizationPushRulesSyncTriggersToIncludePushRuleId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  disable_ddl_transaction!
  milestone '18.5'

  SYNC_TRIGGER_NAME = 'trigger_sync_organization_push_rules_insert_update'
  SYNC_FUNCTION_NAME = 'sync_organization_push_rules_on_insert_update'

  def up
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- Need this here
    # More details - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188143#note_2493525239
    with_lock_retries do
      drop_trigger(:push_rules, SYNC_TRIGGER_NAME)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod

    drop_function(SYNC_FUNCTION_NAME)

    # We need to populate organization_push_rules when push_rules are created or updated
    # this time, we support ID preservation from the push_rules table
    with_lock_retries do
      execute(<<~SQL)
        CREATE OR REPLACE FUNCTION #{SYNC_FUNCTION_NAME}()
          RETURNS TRIGGER
          LANGUAGE plpgsql
        AS $$
         BEGIN
            IF (NEW.organization_id IS NOT NULL AND NEW.is_sample = TRUE) THEN
              INSERT INTO organization_push_rules (
                id,
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
                NEW.id,
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
                id = NEW.id,
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
    end

    # Create the trigger for INSERT and UPDATE operations
    with_lock_retries do
      execute(<<~SQL)
        CREATE TRIGGER #{SYNC_TRIGGER_NAME}
        AFTER INSERT OR UPDATE ON push_rules
        FOR EACH ROW
        EXECUTE FUNCTION #{SYNC_FUNCTION_NAME}();
      SQL
    end
  end

  def down
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- Need this here
    # More details - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188143#note_2493525239
    with_lock_retries do
      drop_trigger(:push_rules, SYNC_TRIGGER_NAME)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod

    drop_function(SYNC_FUNCTION_NAME)

    # Restore the original namespace function (without ID preservation)
    with_lock_retries do
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
    end

    # Restore the original trigger for INSERT and UPDATE operations
    with_lock_retries do
      execute(<<~SQL)
        CREATE TRIGGER #{SYNC_TRIGGER_NAME}
        AFTER INSERT OR UPDATE ON push_rules
        FOR EACH ROW
        EXECUTE FUNCTION #{SYNC_FUNCTION_NAME}();
      SQL
    end
  end
end
