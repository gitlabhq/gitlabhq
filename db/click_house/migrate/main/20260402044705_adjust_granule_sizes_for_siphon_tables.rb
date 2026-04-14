# frozen_string_literal: true

class AdjustGranuleSizesForSiphonTables < ClickHouse::Migration
  TABLE_LIST = %i[
    siphon_deployment_merge_requests
    siphon_deployments
    siphon_environments
    siphon_knowledge_graph_enabled_namespaces
    siphon_members
    siphon_namespace_details
    siphon_namespaces
    siphon_project_authorizations
    siphon_projects
    siphon_users
  ].freeze

  NEW_GRANULARITY = 2048
  DEFAULT_GRANULARITY = 8192

  # Materialized views attached to a table as their FROM source. Must be dropped
  # before the source table is dropped, then recreated afterwards.
  DEPENDENT_VIEWS = {
    siphon_namespaces: %w[
      namespace_traversal_paths_mv
      namespace_traversal_path_refresh_to_projects_mv
    ],
    siphon_projects: %w[
      project_namespace_traversal_paths_mv
    ]
  }.freeze

  def up
    tables_to_recreate = TABLE_LIST.reject { |t| current_index_granularity(t) == NEW_GRANULARITY }

    unless tables_to_recreate.empty?
      drop_dependent_views(tables_to_recreate)
      tables_to_recreate.each do |table|
        execute "DROP TABLE IF EXISTS #{table}"
        execute create_table_sql(table, NEW_GRANULARITY)
      end
    end

    # Always run, handles retry after failure mid-view-recreation, when all tables
    # are already at 2048 so the block above is skipped but views are still missing.
    recreate_missing_views
  end

  def down
    tables_to_recreate = TABLE_LIST.reject { |t| current_index_granularity(t) == DEFAULT_GRANULARITY }

    unless tables_to_recreate.empty?
      drop_dependent_views(tables_to_recreate)
      tables_to_recreate.each do |table|
        execute "DROP TABLE IF EXISTS #{table}"
        execute create_table_sql(table, DEFAULT_GRANULARITY)
      end
    end

    # Always run, same retry-safety rationale as up.
    recreate_missing_views
  end

  private

  def current_index_granularity(table)
    query = ClickHouse::Client::Query.new(
      raw_query: <<~SQL,
        SELECT create_table_query
        FROM system.tables
        WHERE database = {database:String}
          AND name = {table:String}
      SQL
      placeholders: { database: connection.database_name, table: table.to_s }
    )

    row = connection.select(query).first
    return DEFAULT_GRANULARITY unless row

    row['create_table_query'].match?(/index_granularity\s*=\s*2048/) ? NEW_GRANULARITY : DEFAULT_GRANULARITY
  end

  def drop_dependent_views(tables)
    tables.flat_map { |t| DEPENDENT_VIEWS.fetch(t, []) }.uniq.each do |view|
      execute "DROP VIEW IF EXISTS #{view}"
    end
  end

  def recreate_missing_views
    DEPENDENT_VIEWS.values.flatten.uniq.each do |view|
      next if connection.table_exists?(view)

      execute view_sql(view)
    end
  end

  def view_sql(view)
    case view
    when 'namespace_traversal_paths_mv' then namespace_traversal_paths_mv_sql
    when 'namespace_traversal_path_refresh_to_projects_mv'
      namespace_traversal_path_refresh_to_projects_mv_sql
    when 'project_namespace_traversal_paths_mv' then project_namespace_traversal_paths_mv_sql
    end
  end

  def namespace_traversal_paths_mv_sql
    <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS namespace_traversal_paths_mv
      TO namespace_traversal_paths
      AS
      SELECT
          id,
          if(length(traversal_ids) = 0,
             toString(ifNull(organization_id, 0)) || '/',
             toString(ifNull(organization_id, 0)) || '/' || arrayStringConcat(traversal_ids, '/') || '/') as traversal_path,
          _siphon_replicated_at AS version,
          _siphon_deleted AS deleted
      FROM siphon_namespaces;
    SQL
  end

  def project_namespace_traversal_paths_mv_sql
    <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS project_namespace_traversal_paths_mv
      TO project_namespace_traversal_paths
      AS
      WITH cte AS (
        SELECT id, project_namespace_id FROM siphon_projects
      ), namespaces_cte AS (
        SELECT traversal_path, id, version, deleted
        FROM namespace_traversal_paths
        WHERE id IN (SELECT project_namespace_id FROM cte)
      )
      SELECT
        cte.id,
        namespaces_cte.traversal_path,
        namespaces_cte.version,
        namespaces_cte.deleted
      FROM cte
      INNER JOIN namespaces_cte ON namespaces_cte.id = cte.project_namespace_id
    SQL
  end

  # -- verbatim copy of MV DDL from 20260324113914
  def namespace_traversal_path_refresh_to_projects_mv_sql
    <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS namespace_traversal_path_refresh_to_projects_mv TO siphon_projects AS
      WITH
        base AS (
          SELECT id FROM siphon_namespaces WHERE type = 'Project'
        ),
        projects AS (
          SELECT
            id,
            argMax(name, _siphon_replicated_at) AS name,
            argMax(path, _siphon_replicated_at) AS path,
            argMax(description, _siphon_replicated_at) AS description,
            argMax(created_at, _siphon_replicated_at) AS created_at,
            argMax(updated_at, _siphon_replicated_at) AS updated_at,
            argMax(creator_id, _siphon_replicated_at) AS creator_id,
            argMax(namespace_id, _siphon_replicated_at) AS namespace_id,
            argMax(last_activity_at, _siphon_replicated_at) AS last_activity_at,
            argMax(import_url, _siphon_replicated_at) AS import_url,
            argMax(visibility_level, _siphon_replicated_at) AS visibility_level,
            argMax(archived, _siphon_replicated_at) AS archived,
            argMax(avatar, _siphon_replicated_at) AS avatar,
            argMax(merge_requests_template, _siphon_replicated_at) AS merge_requests_template,
            argMax(star_count, _siphon_replicated_at) AS star_count,
            argMax(merge_requests_rebase_enabled, _siphon_replicated_at) AS merge_requests_rebase_enabled,
            argMax(import_type, _siphon_replicated_at) AS import_type,
            argMax(import_source, _siphon_replicated_at) AS import_source,
            argMax(approvals_before_merge, _siphon_replicated_at) AS approvals_before_merge,
            argMax(reset_approvals_on_push, _siphon_replicated_at) AS reset_approvals_on_push,
            argMax(merge_requests_ff_only_enabled, _siphon_replicated_at) AS merge_requests_ff_only_enabled,
            argMax(issues_template, _siphon_replicated_at) AS issues_template,
            argMax(mirror, _siphon_replicated_at) AS mirror,
            argMax(mirror_last_update_at, _siphon_replicated_at) AS mirror_last_update_at,
            argMax(mirror_last_successful_update_at, _siphon_replicated_at) AS mirror_last_successful_update_at,
            argMax(mirror_user_id, _siphon_replicated_at) AS mirror_user_id,
            argMax(shared_runners_enabled, _siphon_replicated_at) AS shared_runners_enabled,
            argMax(build_allow_git_fetch, _siphon_replicated_at) AS build_allow_git_fetch,
            argMax(build_timeout, _siphon_replicated_at) AS build_timeout,
            argMax(mirror_trigger_builds, _siphon_replicated_at) AS mirror_trigger_builds,
            argMax(pending_delete, _siphon_replicated_at) AS pending_delete,
            argMax(public_builds, _siphon_replicated_at) AS public_builds,
            argMax(last_repository_check_failed, _siphon_replicated_at) AS last_repository_check_failed,
            argMax(last_repository_check_at, _siphon_replicated_at) AS last_repository_check_at,
            argMax(only_allow_merge_if_pipeline_succeeds, _siphon_replicated_at) AS only_allow_merge_if_pipeline_succeeds,
            argMax(has_external_issue_tracker, _siphon_replicated_at) AS has_external_issue_tracker,
            argMax(repository_storage, _siphon_replicated_at) AS repository_storage,
            argMax(repository_read_only, _siphon_replicated_at) AS repository_read_only,
            argMax(request_access_enabled, _siphon_replicated_at) AS request_access_enabled,
            argMax(has_external_wiki, _siphon_replicated_at) AS has_external_wiki,
            argMax(ci_config_path, _siphon_replicated_at) AS ci_config_path,
            argMax(lfs_enabled, _siphon_replicated_at) AS lfs_enabled,
            argMax(description_html, _siphon_replicated_at) AS description_html,
            argMax(only_allow_merge_if_all_discussions_are_resolved, _siphon_replicated_at) AS only_allow_merge_if_all_discussions_are_resolved,
            argMax(repository_size_limit, _siphon_replicated_at) AS repository_size_limit,
            argMax(printing_merge_request_link_enabled, _siphon_replicated_at) AS printing_merge_request_link_enabled,
            argMax(auto_cancel_pending_pipelines, _siphon_replicated_at) AS auto_cancel_pending_pipelines,
            argMax(service_desk_enabled, _siphon_replicated_at) AS service_desk_enabled,
            argMax(cached_markdown_version, _siphon_replicated_at) AS cached_markdown_version,
            argMax(delete_error, _siphon_replicated_at) AS delete_error,
            argMax(last_repository_updated_at, _siphon_replicated_at) AS last_repository_updated_at,
            argMax(disable_overriding_approvers_per_merge_request, _siphon_replicated_at) AS disable_overriding_approvers_per_merge_request,
            argMax(storage_version, _siphon_replicated_at) AS storage_version,
            argMax(resolve_outdated_diff_discussions, _siphon_replicated_at) AS resolve_outdated_diff_discussions,
            argMax(remote_mirror_available_overridden, _siphon_replicated_at) AS remote_mirror_available_overridden,
            argMax(only_mirror_protected_branches, _siphon_replicated_at) AS only_mirror_protected_branches,
            argMax(pull_mirror_available_overridden, _siphon_replicated_at) AS pull_mirror_available_overridden,
            argMax(jobs_cache_index, _siphon_replicated_at) AS jobs_cache_index,
            argMax(external_authorization_classification_label, _siphon_replicated_at) AS external_authorization_classification_label,
            argMax(mirror_overwrites_diverged_branches, _siphon_replicated_at) AS mirror_overwrites_diverged_branches,
            argMax(pages_https_only, _siphon_replicated_at) AS pages_https_only,
            argMax(packages_enabled, _siphon_replicated_at) AS packages_enabled,
            argMax(merge_requests_author_approval, _siphon_replicated_at) AS merge_requests_author_approval,
            argMax(pool_repository_id, _siphon_replicated_at) AS pool_repository_id,
            argMax(bfg_object_map, _siphon_replicated_at) AS bfg_object_map,
            argMax(detected_repository_languages, _siphon_replicated_at) AS detected_repository_languages,
            argMax(merge_requests_disable_committers_approval, _siphon_replicated_at) AS merge_requests_disable_committers_approval,
            argMax(require_password_to_approve, _siphon_replicated_at) AS require_password_to_approve,
            argMax(emails_disabled, _siphon_replicated_at) AS emails_disabled,
            argMax(max_pages_size, _siphon_replicated_at) AS max_pages_size,
            argMax(max_artifacts_size, _siphon_replicated_at) AS max_artifacts_size,
            argMax(pull_mirror_branch_prefix, _siphon_replicated_at) AS pull_mirror_branch_prefix,
            argMax(remove_source_branch_after_merge, _siphon_replicated_at) AS remove_source_branch_after_merge,
            argMax(marked_for_deletion_at, _siphon_replicated_at) AS marked_for_deletion_at,
            argMax(marked_for_deletion_by_user_id, _siphon_replicated_at) AS marked_for_deletion_by_user_id,
            argMax(autoclose_referenced_issues, _siphon_replicated_at) AS autoclose_referenced_issues,
            argMax(suggestion_commit_message, _siphon_replicated_at) AS suggestion_commit_message,
            argMax(project_namespace_id, _siphon_replicated_at) AS project_namespace_id,
            argMax(hidden, _siphon_replicated_at) AS hidden,
            argMax(organization_id, _siphon_replicated_at) AS organization_id,
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted,
            now64(6) AS _siphon_replicated_at
            FROM (
              SELECT * FROM siphon_projects
              WHERE project_namespace_id IN (SELECT id FROM base)
            )
          GROUP BY id
          HAVING deleted = false
        )
        SELECT
          projects.id AS id,
          projects.name AS name,
          projects.path AS path,
          projects.description AS description,
          projects.created_at AS created_at,
          projects.updated_at AS updated_at,
          projects.creator_id AS creator_id,
          projects.namespace_id AS namespace_id,
          projects.last_activity_at AS last_activity_at,
          projects.import_url AS import_url,
          projects.visibility_level AS visibility_level,
          projects.archived AS archived,
          projects.avatar AS avatar,
          projects.merge_requests_template AS merge_requests_template,
          projects.star_count AS star_count,
          projects.merge_requests_rebase_enabled AS merge_requests_rebase_enabled,
          projects.import_type AS import_type,
          projects.import_source AS import_source,
          projects.approvals_before_merge AS approvals_before_merge,
          projects.reset_approvals_on_push AS reset_approvals_on_push,
          projects.merge_requests_ff_only_enabled AS merge_requests_ff_only_enabled,
          projects.issues_template AS issues_template,
          projects.mirror AS mirror,
          projects.mirror_last_update_at AS mirror_last_update_at,
          projects.mirror_last_successful_update_at AS mirror_last_successful_update_at,
          projects.mirror_user_id AS mirror_user_id,
          projects.shared_runners_enabled AS shared_runners_enabled,
          projects.build_allow_git_fetch AS build_allow_git_fetch,
          projects.build_timeout AS build_timeout,
          projects.mirror_trigger_builds AS mirror_trigger_builds,
          projects.pending_delete AS pending_delete,
          projects.public_builds AS public_builds,
          projects.last_repository_check_failed AS last_repository_check_failed,
          projects.last_repository_check_at AS last_repository_check_at,
          projects.only_allow_merge_if_pipeline_succeeds AS only_allow_merge_if_pipeline_succeeds,
          projects.has_external_issue_tracker AS has_external_issue_tracker,
          projects.repository_storage AS repository_storage,
          projects.repository_read_only AS repository_read_only,
          projects.request_access_enabled AS request_access_enabled,
          projects.has_external_wiki AS has_external_wiki,
          projects.ci_config_path AS ci_config_path,
          projects.lfs_enabled AS lfs_enabled,
          projects.description_html AS description_html,
          projects.only_allow_merge_if_all_discussions_are_resolved AS only_allow_merge_if_all_discussions_are_resolved,
          projects.repository_size_limit AS repository_size_limit,
          projects.printing_merge_request_link_enabled AS printing_merge_request_link_enabled,
          projects.auto_cancel_pending_pipelines AS auto_cancel_pending_pipelines,
          projects.service_desk_enabled AS service_desk_enabled,
          projects.cached_markdown_version AS cached_markdown_version,
          projects.delete_error AS delete_error,
          projects.last_repository_updated_at AS last_repository_updated_at,
          projects.disable_overriding_approvers_per_merge_request AS disable_overriding_approvers_per_merge_request,
          projects.storage_version AS storage_version,
          projects.resolve_outdated_diff_discussions AS resolve_outdated_diff_discussions,
          projects.remote_mirror_available_overridden AS remote_mirror_available_overridden,
          projects.only_mirror_protected_branches AS only_mirror_protected_branches,
          projects.pull_mirror_available_overridden AS pull_mirror_available_overridden,
          projects.jobs_cache_index AS jobs_cache_index,
          projects.external_authorization_classification_label AS external_authorization_classification_label,
          projects.mirror_overwrites_diverged_branches AS mirror_overwrites_diverged_branches,
          projects.pages_https_only AS pages_https_only,
          projects.packages_enabled AS packages_enabled,
          projects.merge_requests_author_approval AS merge_requests_author_approval,
          projects.pool_repository_id AS pool_repository_id,
          projects.bfg_object_map AS bfg_object_map,
          projects.detected_repository_languages AS detected_repository_languages,
          projects.merge_requests_disable_committers_approval AS merge_requests_disable_committers_approval,
          projects.require_password_to_approve AS require_password_to_approve,
          projects.emails_disabled AS emails_disabled,
          projects.max_pages_size AS max_pages_size,
          projects.max_artifacts_size AS max_artifacts_size,
          projects.pull_mirror_branch_prefix AS pull_mirror_branch_prefix,
          projects.remove_source_branch_after_merge AS remove_source_branch_after_merge,
          projects.marked_for_deletion_at AS marked_for_deletion_at,
          projects.marked_for_deletion_by_user_id AS marked_for_deletion_by_user_id,
          projects.autoclose_referenced_issues AS autoclose_referenced_issues,
          projects.suggestion_commit_message AS suggestion_commit_message,
          projects.project_namespace_id AS project_namespace_id,
          projects.hidden AS hidden,
          projects.organization_id AS organization_id,
          projects.deleted AS _siphon_deleted,
          projects._siphon_replicated_at AS _siphon_replicated_at
        FROM base
        LEFT JOIN projects ON projects.project_namespace_id=base.id
    SQL
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength -- DDL dispatch for 10 tables
  def create_table_sql(table, granularity)
    case table
    when :siphon_deployment_merge_requests then siphon_deployment_merge_requests_sql(granularity)
    when :siphon_deployments               then siphon_deployments_sql(granularity)
    when :siphon_environments              then siphon_environments_sql(granularity)
    when :siphon_knowledge_graph_enabled_namespaces
      siphon_knowledge_graph_enabled_namespaces_sql(granularity)
    when :siphon_members                   then siphon_members_sql(granularity)
    when :siphon_namespace_details         then siphon_namespace_details_sql(granularity)
    when :siphon_namespaces                then siphon_namespaces_sql(granularity)
    when :siphon_project_authorizations    then siphon_project_authorizations_sql(granularity)
    when :siphon_projects                  then siphon_projects_sql(granularity)
    when :siphon_users                     then siphon_users_sql(granularity)
    end
  end
  # rubocop:enable Metrics/MethodLength

  def siphon_deployment_merge_requests_sql(granularity)
    <<~SQL
      CREATE TABLE IF NOT EXISTS siphon_deployment_merge_requests
      (
        deployment_id Int64,
        merge_request_id Int64,
        environment_id Nullable(Int64),
        project_id Int64,
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/'),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        _siphon_deleted Bool DEFAULT FALSE,
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY deployment_id, merge_request_id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, deployment_id, merge_request_id)
      SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = #{granularity}
    SQL
  end

  def siphon_deployments_sql(granularity)
    <<~SQL
      CREATE TABLE IF NOT EXISTS siphon_deployments
      (
        id Int64,
        iid Int64,
        project_id Int64,
        environment_id Int64,
        ref String,
        tag Bool,
        sha String,
        user_id Nullable(Int64),
        deployable_type String DEFAULT '',
        created_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        updated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        on_stop Nullable(String),
        status Int8,
        finished_at Nullable(DateTime64(6, 'UTC')),
        deployable_id Nullable(Int64),
        archived Bool DEFAULT false,
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/'),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        _siphon_deleted Bool DEFAULT FALSE,
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id)
      SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = #{granularity}
    SQL
  end

  def siphon_environments_sql(granularity)
    <<~SQL
      CREATE TABLE IF NOT EXISTS siphon_environments
      (
        id Int64,
        project_id Int64,
        name String,
        created_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        updated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        external_url Nullable(String),
        environment_type Nullable(String),
        state String DEFAULT 'available',
        slug String,
        auto_stop_at Nullable(DateTime64(6, 'UTC')),
        auto_delete_at Nullable(DateTime64(6, 'UTC')),
        tier Nullable(Int8),
        merge_request_id Nullable(Int64),
        cluster_agent_id Nullable(Int64),
        kubernetes_namespace Nullable(String),
        flux_resource_path Nullable(String),
        description Nullable(String),
        description_html Nullable(String),
        cached_markdown_version Nullable(Int64),
        auto_stop_setting Int8 DEFAULT 0,
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/'),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        _siphon_deleted Bool DEFAULT FALSE,
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id)
      SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = #{granularity}
    SQL
  end

  def siphon_knowledge_graph_enabled_namespaces_sql(granularity)
    <<~SQL
      CREATE TABLE IF NOT EXISTS siphon_knowledge_graph_enabled_namespaces
      (
        id Int64,
        root_namespace_id Int64,
        created_at DateTime64(6, 'UTC'),
        updated_at DateTime64(6, 'UTC'),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (root_namespace_id, id)
      SETTINGS index_granularity = #{granularity}
    SQL
  end

  def siphon_members_sql(granularity)
    <<~SQL
      CREATE TABLE IF NOT EXISTS siphon_members
      (
        id Int64,
        access_level Int64,
        source_id Int64,
        source_type String,
        user_id Nullable(Int64),
        notification_level Int64,
        type String,
        created_at DateTime64(6, 'UTC'),
        updated_at DateTime64(6, 'UTC'),
        created_by_id Nullable(Int64),
        invite_email Nullable(String),
        invite_token Nullable(String),
        invite_accepted_at Nullable(DateTime64(6, 'UTC')),
        requested_at Nullable(DateTime64(6, 'UTC')),
        expires_at Nullable(Date32),
        ldap Bool DEFAULT false,
        override Bool DEFAULT false,
        state Int8 DEFAULT 0,
        invite_email_success Bool DEFAULT true,
        member_namespace_id Nullable(Int64),
        member_role_id Nullable(Int64),
        expiry_notified_at Nullable(DateTime64(6, 'UTC')),
        request_accepted_at Nullable(DateTime64(6, 'UTC')),
        traversal_path String DEFAULT multiIf(coalesce(member_namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', member_namespace_id, '0/'), '0/'),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        _siphon_deleted Bool DEFAULT FALSE,
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id)
      SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = #{granularity}
    SQL
  end

  def siphon_namespace_details_sql(granularity)
    <<~SQL
      CREATE TABLE IF NOT EXISTS siphon_namespace_details
      (
        namespace_id Int64,
        created_at Nullable(DateTime64(6, 'UTC')),
        updated_at Nullable(DateTime64(6, 'UTC')),
        cached_markdown_version Nullable(Int64),
        description Nullable(String),
        description_html Nullable(String),
        creator_id Nullable(Int64),
        deleted_at Nullable(DateTime64(6, 'UTC')),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        _siphon_deleted Bool DEFAULT FALSE,
        state_metadata String DEFAULT '{}',
        deletion_scheduled_at Nullable(DateTime64(6, 'UTC'))
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY namespace_id
      SETTINGS index_granularity = #{granularity}
    SQL
  end

  def siphon_namespaces_sql(granularity)
    <<~SQL
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
        organization_id Int64 DEFAULT 0,
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        _siphon_deleted Boolean DEFAULT FALSE,
        state Int8
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
      SETTINGS index_granularity = #{granularity}
    SQL
  end

  def siphon_project_authorizations_sql(granularity)
    <<~SQL
      CREATE TABLE IF NOT EXISTS siphon_project_authorizations
      (
        user_id Int64,
        project_id Int64,
        access_level Int64,
        is_unique Nullable(Bool),
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/'),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        _siphon_deleted Bool DEFAULT FALSE,
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY user_id, project_id, access_level
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, user_id, project_id, access_level)
      SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = #{granularity}
    SQL
  end

  def siphon_projects_sql(granularity)
    <<~SQL
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
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        _siphon_deleted Boolean DEFAULT FALSE,
        PROJECTION by_project_namespace_id (
          SELECT *
          ORDER BY project_namespace_id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
      SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = #{granularity}
    SQL
  end

  def siphon_users_sql(granularity)
    <<~SQL
      CREATE TABLE IF NOT EXISTS siphon_users
      (
        id Int64,
        email String DEFAULT '',
        sign_in_count Int64 DEFAULT 0,
        current_sign_in_at Nullable(DateTime64(6, 'UTC')),
        last_sign_in_at Nullable(DateTime64(6, 'UTC')),
        current_sign_in_ip Nullable(String),
        last_sign_in_ip Nullable(String),
        created_at Nullable(DateTime64(6, 'UTC')),
        updated_at Nullable(DateTime64(6, 'UTC')),
        name String DEFAULT '',
        admin Bool DEFAULT false,
        projects_limit Int64,
        failed_attempts Int64 DEFAULT 0,
        locked_at Nullable(DateTime64(6, 'UTC')),
        username String DEFAULT '',
        can_create_group Bool DEFAULT true,
        can_create_team Bool DEFAULT true,
        state String DEFAULT '',
        color_scheme_id Int64 DEFAULT 1,
        created_by_id Nullable(Int64),
        last_credential_check_at Nullable(DateTime64(6, 'UTC')),
        avatar Nullable(String),
        unconfirmed_email String DEFAULT '',
        hide_no_ssh_key Bool DEFAULT false,
        admin_email_unsubscribed_at Nullable(DateTime64(6, 'UTC')),
        notification_email Nullable(String),
        hide_no_password Bool DEFAULT false,
        password_automatically_set Bool DEFAULT false,
        public_email Nullable(String),
        dashboard Int64 DEFAULT 0,
        project_view Int64 DEFAULT 2,
        consumed_timestep Nullable(Int64),
        layout Int64 DEFAULT 0,
        hide_project_limit Bool DEFAULT false,
        note Nullable(String),
        otp_grace_period_started_at Nullable(DateTime64(6, 'UTC')),
        external Bool DEFAULT false,
        auditor Bool DEFAULT false,
        require_two_factor_authentication_from_group Bool DEFAULT false,
        two_factor_grace_period Int64 DEFAULT 48,
        last_activity_on Nullable(Date32),
        notified_of_own_activity Nullable(Bool) DEFAULT false,
        preferred_language Nullable(String),
        theme_id Nullable(Int8),
        accepted_term_id Nullable(Int64),
        private_profile Bool DEFAULT false,
        roadmap_layout Nullable(Int8),
        include_private_contributions Nullable(Bool),
        commit_email Nullable(String),
        group_view Nullable(Int64),
        managing_group_id Nullable(Int64),
        first_name String DEFAULT '',
        last_name String DEFAULT '',
        user_type Int8 DEFAULT 0,
        onboarding_in_progress Bool DEFAULT false,
        color_mode_id Int8 DEFAULT 1,
        composite_identity_enforced Bool DEFAULT false,
        organization_id Int64,
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
      SETTINGS index_granularity = #{granularity}
    SQL
  end
end
