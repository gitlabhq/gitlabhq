# frozen_string_literal: true

class CreateSiphonNamespaces < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_namespaces
      (
        id Int64,
        name String,
        path String,
        owner_id Nullable(Int64),
        created_at Nullable(DateTime64(6, 'UTC')),
        updated_at Nullable(DateTime64(6, 'UTC')),
        type LowCardinality(String) DEFAULT 'User',
        description String DEFAULT '',
        avatar Nullable(String),
        membership_lock Nullable(Bool) DEFAULT false,
        share_with_group_lock Nullable(Bool) DEFAULT false,
        visibility_level Int64 DEFAULT 20,
        request_access_enabled Bool DEFAULT true,
        ldap_sync_status LowCardinality(String) DEFAULT 'ready',
        ldap_sync_error Nullable(String),
        ldap_sync_last_update_at Nullable(DateTime64(6, 'UTC')),
        ldap_sync_last_successful_update_at Nullable(DateTime64(6, 'UTC')),
        ldap_sync_last_sync_at Nullable(DateTime64(6, 'UTC')),
        description_html Nullable(String),
        lfs_enabled Nullable(Bool),
        parent_id Nullable(Int64),
        shared_runners_minutes_limit Nullable(Int64),
        repository_size_limit Nullable(Int64),
        require_two_factor_authentication Bool DEFAULT false,
        two_factor_grace_period Int64 DEFAULT 48,
        cached_markdown_version Nullable(Int64),
        project_creation_level Nullable(Int64),
        runners_token Nullable(String),
        file_template_project_id Nullable(Int64),
        saml_discovery_token Nullable(String),
        runners_token_encrypted Nullable(String),
        custom_project_templates_group_id Nullable(Int64),
        auto_devops_enabled Nullable(Bool),
        extra_shared_runners_minutes_limit Nullable(Int64),
        last_ci_minutes_notification_at Nullable(DateTime64(6, 'UTC')),
        last_ci_minutes_usage_notification_level Nullable(Int64),
        subgroup_creation_level Nullable(Int64) DEFAULT 1,
        emails_disabled Nullable(Bool),
        max_pages_size Nullable(Int64),
        max_artifacts_size Nullable(Int64),
        mentions_disabled Nullable(Bool),
        default_branch_protection Nullable(Int8),
        unlock_membership_to_ldap Nullable(Bool),
        max_personal_access_token_lifetime Nullable(Int64),
        push_rule_id Nullable(Int64),
        shared_runners_enabled Bool DEFAULT true,
        allow_descendants_override_disabled_shared_runners Bool DEFAULT false,
        traversal_ids Array(Int64) DEFAULT [],
        organization_id Nullable(Int64),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Boolean DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_namespaces
    SQL
  end
end
