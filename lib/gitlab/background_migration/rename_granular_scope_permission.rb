# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RenameGranularScopePermission < BatchedMigrationJob
      include Gitlab::Database::MigrationHelpers::GranularScopePermissions

      RENAMES = {
        # user_ prefix
        'read_user_ssh_key' => 'read_ssh_key',
        'create_user_ssh_key' => 'create_ssh_key',
        'delete_user_ssh_key' => 'delete_ssh_key',
        'read_user_gpg_key' => 'read_gpg_key',
        'create_user_gpg_key' => 'create_gpg_key',
        'delete_user_gpg_key' => 'delete_gpg_key',
        'revoke_user_gpg_key' => 'revoke_gpg_key',
        'read_user_email' => 'read_email',
        'create_user_email' => 'create_email',
        'delete_user_email' => 'delete_email',
        'read_user_counts' => 'read_counts',
        'create_user_support_pin' => 'create_support_pin',
        'read_user_support_pin' => 'read_support_pin',
        'read_user_activity' => 'read_activity',
        'read_user_association' => 'read_association',
        'update_user_avatar' => 'update_avatar',
        'read_user_follower' => 'read_follower',
        'read_user_following' => 'read_following',
        'read_user_preference' => 'read_preference',
        'update_user_preference' => 'update_preference',
        'read_user_project_deploy_key' => 'read_deploy_key',
        'read_user_status' => 'read_status',
        'update_user_status' => 'update_status',
        # project_ prefix
        'read_project_export' => 'read_export',
        'create_project_export' => 'create_export',
        'download_project_export' => 'download_export',
        'read_project_import' => 'read_import',
        'create_project_import' => 'create_import',
        'read_project_relation_export' => 'read_export',
        'create_project_relation_export' => 'create_export',
        'download_project_relation_export' => 'download_export',
        'read_project_relation_import' => 'read_import',
        'create_project_relation_import' => 'create_import',
        'read_project_alias' => 'read_alias',
        'create_project_alias' => 'create_alias',
        'delete_project_alias' => 'delete_alias',
        # group_ prefix
        'download_group_export' => 'download_export',
        'start_group_export' => 'start_export',
        'create_group_import' => 'create_import',
        # granularity: merge into parent permission
        'read_starred_project' => 'read_project',
        'read_merge_request_approval_state' => 'read_merge_request',
        'read_merge_request_label_event' => 'read_merge_request',
        'read_issue_label_event' => 'read_work_item',
        'read_epic_label_event' => 'read_work_item',
        'update_webhook_url_variable' => 'update_webhook',
        'delete_webhook_url_variable' => 'update_webhook',
        'update_webhook_custom_header' => 'update_webhook',
        'delete_webhook_custom_header' => 'update_webhook',
        # granularity: rename action verb
        'test_webhook' => 'trigger_webhook',
        'resend_webhook_event' => 'trigger_webhook',
        'increment_usage_data_metric' => 'update_usage_data_metric',
        # granularity: consolidate import/export
        'read_relation_export' => 'read_export',
        'create_relation_export' => 'create_export',
        'download_relation_export' => 'download_export',
        'read_relation_import' => 'read_import',
        'create_relation_import' => 'create_import',
        'read_bulk_import' => 'read_import',
        'create_bulk_import' => 'create_import',
        'cancel_bulk_import' => 'cancel_import',
        'read_bulk_import_entity' => 'read_import',
        'read_bulk_import_entity_failure' => 'read_import',
        'create_bitbucket_import' => 'create_import',
        'create_bitbucket_server_import' => 'create_import',
        'create_github_import' => 'create_import',
        'cancel_github_import' => 'cancel_import',
        'create_github_gist_import' => 'create_import'
      }.freeze

      feature_category :permissions
    end
  end
end
