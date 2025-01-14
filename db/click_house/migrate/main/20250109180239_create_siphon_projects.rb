# frozen_string_literal: true

class CreateSiphonProjects < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_projects
      (
        id Int64,
        name Nullable(String),
        path Nullable(String),
        description Nullable(String),
        created_at Nullable(DateTime64(6, 'UTC')),
        updated_at Nullable(DateTime64(6, 'UTC')),
        creator_id Nullable(Int64),
        namespace_id Int64,
        last_activity_at Nullable(DateTime64(6, 'UTC')),
        import_url Nullable(String),
        visibility_level Int64 DEFAULT 0,
        archived Boolean DEFAULT false,
        avatar Nullable(String),
        merge_requests_template Nullable(String),
        star_count Int64 DEFAULT 0,
        merge_requests_rebase_enabled Nullable(Boolean) DEFAULT false,
        import_type Nullable(String),
        import_source Nullable(String),
        approvals_before_merge Int64 DEFAULT 0,
        reset_approvals_on_push Nullable(Boolean) DEFAULT true,
        merge_requests_ff_only_enabled Nullable(Boolean) DEFAULT false,
        issues_template Nullable(String),
        mirror Boolean DEFAULT false,
        mirror_last_update_at Nullable(DateTime64(6, 'UTC')),
        mirror_last_successful_update_at Nullable(DateTime64(6, 'UTC')),
        mirror_user_id Nullable(Int64),
        shared_runners_enabled Boolean DEFAULT true,
        runners_token Nullable(String),
        build_allow_git_fetch Boolean DEFAULT true,
        build_timeout Int64 DEFAULT 3600,
        mirror_trigger_builds Boolean DEFAULT false,
        pending_delete Nullable(Boolean) DEFAULT false,
        public_builds Boolean DEFAULT true,
        last_repository_check_failed Nullable(Boolean),
        last_repository_check_at Nullable(DateTime64(6, 'UTC')),
        only_allow_merge_if_pipeline_succeeds Boolean DEFAULT false,
        has_external_issue_tracker Nullable(Boolean),
        repository_storage String DEFAULT 'default',
        repository_read_only Nullable(Boolean),
        request_access_enabled Boolean DEFAULT true,
        has_external_wiki Nullable(Boolean),
        ci_config_path Nullable(String),
        lfs_enabled Nullable(Boolean),
        description_html Nullable(String),
        only_allow_merge_if_all_discussions_are_resolved Nullable(Boolean),
        repository_size_limit Nullable(Int64),
        printing_merge_request_link_enabled Boolean DEFAULT true,
        auto_cancel_pending_pipelines Int64 DEFAULT 1,
        service_desk_enabled Nullable(Boolean) DEFAULT true,
        cached_markdown_version Nullable(Int64),
        delete_error Nullable(String),
        last_repository_updated_at Nullable(DateTime64(6, 'UTC')),
        disable_overriding_approvers_per_merge_request Nullable(Boolean),
        storage_version Nullable(Int8),
        resolve_outdated_diff_discussions Nullable(Boolean),
        remote_mirror_available_overridden Nullable(Boolean),
        only_mirror_protected_branches Nullable(Boolean),
        pull_mirror_available_overridden Nullable(Boolean),
        jobs_cache_index Nullable(Int64),
        external_authorization_classification_label Nullable(String),
        mirror_overwrites_diverged_branches Nullable(Boolean),
        pages_https_only Nullable(Boolean) DEFAULT true,
        external_webhook_token Nullable(String),
        packages_enabled Nullable(Boolean),
        merge_requests_author_approval Nullable(Boolean) DEFAULT false,
        pool_repository_id Nullable(Int64),
        runners_token_encrypted Nullable(String),
        bfg_object_map Nullable(String),
        detected_repository_languages Nullable(Boolean),
        merge_requests_disable_committers_approval Nullable(Boolean),
        require_password_to_approve Nullable(Boolean),
        emails_disabled Nullable(Boolean),
        max_pages_size Nullable(Int64),
        max_artifacts_size Nullable(Int64),
        pull_mirror_branch_prefix Nullable(String),
        remove_source_branch_after_merge Nullable(Boolean),
        marked_for_deletion_at Nullable(Date32),
        marked_for_deletion_by_user_id Nullable(Int64),
        autoclose_referenced_issues Nullable(Boolean),
        suggestion_commit_message Nullable(String),
        project_namespace_id Nullable(Int64),
        hidden Boolean DEFAULT false,
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
      DROP TABLE IF EXISTS siphon_projects
    SQL
  end
end
