# frozen_string_literal: true

class UpdateGroupPushRulesSyncTriggersToIncludePushRuleId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  disable_ddl_transaction!
  milestone '18.3'

  NAMESPACE_SYNC_TRIGGER_NAME = 'trigger_sync_namespace_to_group_push_rules'

  NAMESPACE_SYNC_FUNCTION_NAME = 'sync_namespace_to_group_push_rules'

  def up
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- Need this here
    # More details - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188143#note_2493525239
    with_lock_retries do
      drop_trigger(:namespaces, NAMESPACE_SYNC_TRIGGER_NAME)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod

    drop_function(NAMESPACE_SYNC_FUNCTION_NAME)

    # Create updated function with ID preservation
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{NAMESPACE_SYNC_FUNCTION_NAME}()
        RETURNS TRIGGER
        LANGUAGE plpgsql
      AS $$
      DECLARE
        push_rule RECORD;
      BEGIN
        IF NEW.type != 'Group' THEN
          RETURN NEW;
        END IF;

        IF OLD.push_rule_id IS NOT NULL AND NEW.push_rule_id IS NULL THEN
          DELETE FROM group_push_rules WHERE group_id = NEW.id;
          RETURN NEW;
        END IF;

        IF NEW.push_rule_id IS NOT NULL AND (OLD.push_rule_id IS NULL OR OLD.push_rule_id != NEW.push_rule_id) THEN
          SELECT * INTO push_rule FROM push_rules WHERE id = NEW.push_rule_id;

          IF FOUND THEN
            INSERT INTO group_push_rules (
              id,
              group_id,
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
              push_rule.id,
              NEW.id,
              push_rule.max_file_size,
              push_rule.member_check,
              push_rule.prevent_secrets,
              push_rule.commit_committer_name_check,
              push_rule.deny_delete_tag,
              push_rule.reject_unsigned_commits,
              push_rule.commit_committer_check,
              push_rule.reject_non_dco_commits,
              push_rule.commit_message_regex,
              push_rule.branch_name_regex,
              push_rule.commit_message_negative_regex,
              push_rule.author_email_regex,
              push_rule.file_name_regex,
              push_rule.created_at,
              push_rule.updated_at
            )
            ON CONFLICT (group_id) DO UPDATE SET
              id = push_rule.id,
              max_file_size = push_rule.max_file_size,
              member_check = push_rule.member_check,
              prevent_secrets = push_rule.prevent_secrets,
              reject_unsigned_commits = push_rule.reject_unsigned_commits,
              commit_committer_check = push_rule.commit_committer_check,
              deny_delete_tag = push_rule.deny_delete_tag,
              reject_non_dco_commits = push_rule.reject_non_dco_commits,
              commit_committer_name_check = push_rule.commit_committer_name_check,
              commit_message_regex = push_rule.commit_message_regex,
              branch_name_regex = push_rule.branch_name_regex,
              commit_message_negative_regex = push_rule.commit_message_negative_regex,
              author_email_regex = push_rule.author_email_regex,
              file_name_regex = push_rule.file_name_regex,
              updated_at = push_rule.updated_at;
          END IF;
        END IF;

        RETURN NEW;
      END;
      $$;
    SQL

    with_lock_retries do
      execute(<<~SQL)
        CREATE TRIGGER #{NAMESPACE_SYNC_TRIGGER_NAME}
        AFTER UPDATE ON namespaces
        FOR EACH ROW
        WHEN (OLD.push_rule_id IS DISTINCT FROM NEW.push_rule_id)
        EXECUTE FUNCTION #{NAMESPACE_SYNC_FUNCTION_NAME}();
      SQL
    end
  end

  def down
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- Need this here
    # More details - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188143#note_2493525239
    with_lock_retries do
      drop_trigger(:namespaces, NAMESPACE_SYNC_TRIGGER_NAME)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod

    drop_function(NAMESPACE_SYNC_FUNCTION_NAME)

    # Restore the original namespace function (without ID preservation)
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{NAMESPACE_SYNC_FUNCTION_NAME}()
        RETURNS TRIGGER
        LANGUAGE plpgsql
      AS $$
      DECLARE
        push_rule RECORD;
      BEGIN
        IF NEW.type != 'Group' THEN
          RETURN NEW;
        END IF;

        IF OLD.push_rule_id IS NOT NULL AND NEW.push_rule_id IS NULL THEN
          DELETE FROM group_push_rules WHERE group_id = NEW.id;
          RETURN NEW;
        END IF;

        IF NEW.push_rule_id IS NOT NULL AND (OLD.push_rule_id IS NULL OR OLD.push_rule_id != NEW.push_rule_id) THEN
          SELECT * INTO push_rule FROM push_rules WHERE id = NEW.push_rule_id;

          IF FOUND THEN
            INSERT INTO group_push_rules (
              group_id,
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
              push_rule.max_file_size,
              push_rule.member_check,
              push_rule.prevent_secrets,
              push_rule.commit_committer_name_check,
              push_rule.deny_delete_tag,
              push_rule.reject_unsigned_commits,
              push_rule.commit_committer_check,
              push_rule.reject_non_dco_commits,
              push_rule.commit_message_regex,
              push_rule.branch_name_regex,
              push_rule.commit_message_negative_regex,
              push_rule.author_email_regex,
              push_rule.file_name_regex,
              push_rule.created_at,
              push_rule.updated_at
            )
            ON CONFLICT (group_id) DO UPDATE SET
              max_file_size = push_rule.max_file_size,
              member_check = push_rule.member_check,
              prevent_secrets = push_rule.prevent_secrets,
              reject_unsigned_commits = push_rule.reject_unsigned_commits,
              commit_committer_check = push_rule.commit_committer_check,
              deny_delete_tag = push_rule.deny_delete_tag,
              reject_non_dco_commits = push_rule.reject_non_dco_commits,
              commit_committer_name_check = push_rule.commit_committer_name_check,
              commit_message_regex = push_rule.commit_message_regex,
              branch_name_regex = push_rule.branch_name_regex,
              commit_message_negative_regex = push_rule.commit_message_negative_regex,
              author_email_regex = push_rule.author_email_regex,
              file_name_regex = push_rule.file_name_regex,
              updated_at = push_rule.updated_at;
          END IF;
        END IF;

        RETURN NEW;
      END;
      $$;
    SQL

    # Recreate the original Namespace trigger
    with_lock_retries do
      execute(<<~SQL)
        CREATE TRIGGER #{NAMESPACE_SYNC_TRIGGER_NAME}
        AFTER UPDATE ON namespaces
        FOR EACH ROW
        WHEN (OLD.push_rule_id IS DISTINCT FROM NEW.push_rule_id)
        EXECUTE FUNCTION #{NAMESPACE_SYNC_FUNCTION_NAME}();
      SQL
    end
  end
end
