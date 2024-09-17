# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'spec', 'db', 'schema_support') if Gitlab.ee?

RSpec.describe 'Database schema', feature_category: :database do
  prepend_mod_with('DB::SchemaSupport')

  let(:tables) { connection.tables }
  let(:columns_name_with_jsonb) { retrieve_columns_name_with_jsonb }

  IGNORED_INDEXES_ON_FKS = {
    ai_testing_terms_acceptances: %w[user_id], # testing terms only have 1 entry, and if the user is deleted the record should remain
    ci_build_trace_metadata: [%w[partition_id build_id], %w[partition_id trace_artifact_id]], # the index on build_id is enough
    ci_builds: [%w[partition_id stage_id], %w[partition_id execution_config_id], %w[auto_canceled_by_partition_id auto_canceled_by_id], %w[upstream_pipeline_partition_id upstream_pipeline_id], %w[partition_id commit_id]], # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142804#note_1745483081
    ci_build_needs: %w[project_id], # we will create async index, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163429#note_2065627176
    ci_daily_build_group_report_results: [%w[partition_id last_pipeline_id]], # index on last_pipeline_id is sufficient
    ci_pipeline_artifacts: [%w[partition_id pipeline_id]], # index on pipeline_id is sufficient
    ci_pipeline_chat_data: [%w[partition_id pipeline_id]], # index on pipeline_id is sufficient
    ci_pipeline_messages: [%w[partition_id pipeline_id]], # index on pipeline_id is sufficient
    ci_pipeline_metadata: [%w[partition_id pipeline_id]], # index on pipeline_id is sufficient
    ci_pipeline_variables: [%w[partition_id pipeline_id]], # index on pipeline_id is sufficient
    ci_pipelines: [%w[auto_canceled_by_partition_id auto_canceled_by_id]], # index on auto_canceled_by_id is sufficient
    ci_pipelines_config: [%w[partition_id pipeline_id]], # index on pipeline_id is sufficient
    ci_sources_pipelines: [%w[source_partition_id source_pipeline_id], %w[partition_id pipeline_id]],
    ci_sources_projects: [%w[partition_id pipeline_id]], # index on pipeline_id is sufficient
    ci_stages: [%w[partition_id pipeline_id]], # the index on pipeline_id is sufficient
    notes: %w[namespace_id], # this index is added in an async manner, hence it needs to be ignored in the first phase.
    p_ci_build_trace_metadata: [%w[partition_id build_id], %w[partition_id trace_artifact_id]], # the index on build_id is enough
    p_ci_builds: [%w[partition_id stage_id], %w[partition_id execution_config_id], %w[auto_canceled_by_partition_id auto_canceled_by_id], %w[upstream_pipeline_partition_id upstream_pipeline_id], %w[partition_id commit_id]], # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142804#note_1745483081
    p_ci_builds_execution_configs: [%w[partition_id pipeline_id]], # the index on pipeline_id is enough
    p_ci_pipelines: [%w[auto_canceled_by_partition_id auto_canceled_by_id]], # index on auto_canceled_by_id is sufficient
    p_ci_pipeline_variables: [%w[partition_id pipeline_id]], # index on pipeline_id is sufficient
    p_ci_stages: [%w[partition_id pipeline_id]], # the index on pipeline_id is sufficient
    # `search_index_id index_type` is the composite foreign key configured for `search_namespace_index_assignments`,
    # but in Search::NamespaceIndexAssignment model, only `search_index_id` is used as foreign key and indexed
    search_namespace_index_assignments: [%w[search_index_id index_type]],
    slack_integrations_scopes: [%w[slack_api_scope_id]],
    snippets: %w[organization_id], # this index is added in an async manner, hence it needs to be ignored in the first phase.
    users: [%w[accepted_term_id]],
    subscription_add_on_purchases: [["subscription_add_on_id"]] # index handled via composite index with namespace_id
  }.with_indifferent_access.freeze

  # If splitting FK and table removal into two MRs as suggested in the docs, use this constant in the initial FK removal MR.
  # In the subsequent table removal MR, remove the entries.
  # See: https://docs.gitlab.com/ee/development/migration_style_guide.html#dropping-a-database-table
  REMOVED_FKS = {
    # example_table: %w[example_column]
    alert_management_alerts: %w[prometheus_alert_id]
  }.with_indifferent_access.freeze

  # List of columns historically missing a FK, don't add more columns
  # See: https://docs.gitlab.com/ee/development/database/foreign_keys.html#naming-foreign-keys
  IGNORED_FK_COLUMNS = {
    abuse_reports: %w[reporter_id user_id],
    abuse_report_notes: %w[discussion_id],
    ai_code_suggestion_events: %w[user_id],
    application_settings: %w[performance_bar_allowed_group_id slack_app_id snowplow_app_id eks_account_id eks_access_key_id],
    approvals: %w[user_id project_id],
    approver_groups: %w[target_id],
    approvers: %w[target_id user_id],
    analytics_cycle_analytics_aggregations: %w[last_full_issues_id last_full_merge_requests_id last_incremental_issues_id last_full_run_issues_id last_full_run_merge_requests_id last_incremental_merge_requests_id last_consistency_check_issues_stage_event_hash_id last_consistency_check_issues_issuable_id last_consistency_check_merge_requests_stage_event_hash_id last_consistency_check_merge_requests_issuable_id],
    analytics_cycle_analytics_merge_request_stage_events: %w[author_id group_id merge_request_id milestone_id project_id stage_event_hash_id state_id],
    analytics_cycle_analytics_issue_stage_events: %w[author_id group_id issue_id milestone_id project_id stage_event_hash_id state_id sprint_id],
    analytics_cycle_analytics_stage_event_hashes: %w[organization_id],
    audit_events: %w[author_id entity_id target_id],
    user_audit_events: %w[author_id user_id target_id],
    group_audit_events: %w[author_id group_id target_id],
    project_audit_events: %w[author_id project_id target_id],
    instance_audit_events: %w[author_id target_id],
    award_emoji: %w[awardable_id user_id],
    aws_roles: %w[role_external_id],
    boards: %w[milestone_id iteration_id],
    broadcast_messages: %w[namespace_id],
    chat_names: %w[chat_id team_id user_id],
    chat_teams: %w[team_id],
    ci_builds: %w[project_id runner_id user_id erased_by_id trigger_request_id partition_id auto_canceled_by_partition_id execution_config_id upstream_pipeline_partition_id],
    ci_builds_metadata: %w[partition_id project_id build_id],
    ci_build_needs: %w[project_id],
    ci_daily_build_group_report_results: %w[partition_id],
    ci_deleted_objects: %w[project_id],
    ci_job_artifacts: %w[partition_id project_id job_id],
    ci_namespace_monthly_usages: %w[namespace_id],
    ci_pipeline_artifacts: %w[partition_id],
    ci_pipeline_chat_data: %w[partition_id],
    ci_pipelines_config: %w[partition_id],
    ci_pipeline_messages: %w[partition_id],
    ci_pipeline_metadata: %w[partition_id],
    ci_pipeline_variables: %w[partition_id pipeline_id project_id],
    ci_pipelines: %w[partition_id auto_canceled_by_partition_id],
    p_ci_pipelines: %w[partition_id auto_canceled_by_partition_id auto_canceled_by_id],
    p_ci_runner_machine_builds: %w[project_id],
    ci_runner_projects: %w[runner_id],
    ci_sources_pipelines: %w[partition_id source_partition_id source_job_id],
    ci_sources_projects: %w[partition_id],
    ci_stages: %w[partition_id project_id pipeline_id],
    ci_trigger_requests: %w[commit_id],
    ci_job_artifact_states: %w[partition_id project_id],
    cluster_providers_aws: %w[security_group_id vpc_id access_key_id],
    cluster_providers_gcp: %w[gcp_project_id operation_id],
    compliance_management_frameworks: %w[group_id],
    commit_user_mentions: %w[commit_id],
    dependency_list_export_parts: %w[start_id end_id],
    dep_ci_build_trace_sections: %w[build_id],
    deploy_keys_projects: %w[deploy_key_id],
    deployments: %w[deployable_id user_id],
    draft_notes: %w[discussion_id commit_id],
    epics: %w[updated_by_id last_edited_by_id state_id],
    events: %w[target_id],
    forked_project_links: %w[forked_from_project_id],
    geo_event_log: %w[hashed_storage_attachments_event_id repositories_changed_event_id],
    geo_node_statuses: %w[last_event_id cursor_last_event_id],
    geo_nodes: %w[oauth_application_id],
    geo_repository_deleted_events: %w[project_id],
    ghost_user_migrations: %w[initiator_user_id],
    gitlab_subscription_histories: %w[gitlab_subscription_id hosted_plan_id namespace_id],
    identities: %w[user_id],
    import_failures: %w[project_id],
    issues: %w[last_edited_by_id state_id],
    issue_emails: %w[email_message_id],
    jira_tracker_data: %w[jira_issue_transition_id],
    keys: %w[user_id],
    label_links: %w[target_id],
    ldap_group_links: %w[group_id],
    members: %w[source_id created_by_id],
    merge_requests: %w[last_edited_by_id state_id],
    merge_requests_compliance_violations: %w[target_project_id],
    merge_request_diffs: %w[project_id],
    merge_request_diff_commits: %w[commit_author_id committer_id],
    # merge_request_diff_commits_b5377a7a34 is the temporary table for the merge_request_diff_commits partitioning
    # backfill. It will get foreign keys after the partitioning is finished.
    merge_request_diff_commits_b5377a7a34: %w[merge_request_diff_id commit_author_id committer_id project_id],
    # merge_request_diff_files_99208b8fac is the temporary table for the merge_request_diff_commits partitioning
    # backfill. It will get foreign keys after the partitioning is finished.
    merge_request_diff_files_99208b8fac: %w[merge_request_diff_id project_id],
    merge_request_user_mentions: %w[project_id],
    namespaces: %w[owner_id parent_id],
    namespace_descendants: %w[namespace_id],
    notes: %w[author_id commit_id noteable_id updated_by_id resolved_by_id confirmed_by_id discussion_id namespace_id],
    notification_settings: %w[source_id],
    oauth_access_grants: %w[resource_owner_id application_id],
    oauth_access_tokens: %w[resource_owner_id application_id],
    oauth_applications: %w[owner_id],
    oauth_device_grants: %w[resource_owner_id application_id],
    packages_package_files: %w[project_id],
    p_ci_builds: %w[erased_by_id trigger_request_id partition_id auto_canceled_by_partition_id execution_config_id upstream_pipeline_partition_id],
    p_ci_builds_metadata: %w[project_id build_id partition_id],
    p_batched_git_ref_updates_deletions: %w[project_id partition_id],
    p_catalog_resource_sync_events: %w[catalog_resource_id project_id partition_id],
    p_catalog_resource_component_usages: %w[used_by_project_id], # No FK constraint because we want to preserve historical usage data
    p_ci_finished_build_ch_sync_events: %w[build_id],
    p_ci_finished_pipeline_ch_sync_events: %w[pipeline_id project_namespace_id],
    p_ci_job_annotations: %w[partition_id job_id project_id],
    p_ci_job_artifacts: %w[partition_id project_id job_id],
    p_ci_pipeline_variables: %w[partition_id pipeline_id project_id],
    p_ci_builds_execution_configs: %w[partition_id],
    p_ci_stages: %w[partition_id project_id pipeline_id],
    project_build_artifacts_size_refreshes: %w[last_job_artifact_id],
    project_data_transfers: %w[project_id namespace_id],
    project_error_tracking_settings: %w[sentry_project_id],
    project_statistics: %w[namespace_id],
    projects: %w[ci_id mirror_user_id],
    redirect_routes: %w[source_id],
    repository_languages: %w[programming_language_id],
    routes: %w[source_id],
    sent_notifications: %w[project_id noteable_id recipient_id commit_id in_reply_to_discussion_id],
    slack_integrations: %w[team_id user_id bot_user_id], # these are external Slack IDs
    snippets: %w[author_id],
    spam_logs: %w[user_id],
    status_check_responses: %w[external_approval_rule_id],
    subscriptions: %w[user_id subscribable_id],
    suggestions: %w[commit_id],
    taggings: %w[tag_id taggable_id tagger_id],
    timelogs: %w[user_id],
    todos: %w[target_id commit_id],
    uploads: %w[model_id],
    user_agent_details: %w[subject_id],
    users: %w[color_mode_id color_scheme_id created_by_id theme_id managing_group_id],
    users_star_projects: %w[user_id],
    vulnerability_occurrence_pipelines: %w[project_id],
    vulnerability_finding_links: %w[project_id],
    vulnerability_identifiers: %w[external_id],
    vulnerability_occurrence_identifiers: %w[project_id],
    vulnerability_scanners: %w[external_id],
    vulnerability_state_transitions: %w[state_changed_at_pipeline_id],
    security_scans: %w[pipeline_id project_id], # foreign key is not added as ci_pipeline table will be moved into different db soon
    dependency_list_exports: %w[pipeline_id], # foreign key is not added as ci_pipeline table is in different db
    vulnerability_reads: %w[cluster_agent_id namespace_id], # namespace_id is a denormalization of `project.namespace`
    # See: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87584
    # Fixes performance issues with the deletion of web-hooks with many log entries
    web_hook_logs: %w[web_hook_id],
    webauthn_registrations: %w[u2f_registration_id], # this column will be dropped
    ml_candidates: %w[internal_id],
    value_stream_dashboard_counts: %w[namespace_id],
    vulnerability_export_parts: %w[start_id end_id],
    zoekt_indices: %w[namespace_id], # needed for cells sharding key
    zoekt_repositories: %w[namespace_id project_identifier], # needed for cells sharding key
    zoekt_tasks: %w[project_identifier partition_id zoekt_repository_id], # needed for: cells sharding key, partitioning, and performance reasons
    # TODO: To remove with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155256
    approval_group_rules: %w[approval_policy_rule_id],
    approval_project_rules: %w[approval_policy_rule_id],
    approval_merge_request_rules: %w[approval_policy_rule_id],
    scan_result_policy_violations: %w[approval_policy_rule_id],
    software_license_policies: %w[approval_policy_rule_id],
    ai_testing_terms_acceptances: %w[user_id], # testing terms only have 1 entry, and if the user is deleted the record should remain
    namespace_settings: %w[early_access_program_joined_by_id], # isn't used inside product itself. Only through Snowflake
    workspaces_agent_config_versions: %w[item_id] # polymorphic associations
  }.with_indifferent_access.freeze

  context 'for table' do
    Gitlab::Database::EachDatabase.each_connection do |connection, _|
      schemas_for_connection = Gitlab::Database.gitlab_schemas_for_connection(connection)
      connection.tables.sort.each do |table|
        table_schema = Gitlab::Database::GitlabSchema.table_schema(table)
        next unless schemas_for_connection.include?(table_schema)

        describe table do
          let(:indexes) { connection.indexes(table) }
          let(:columns) { connection.columns(table) }
          let(:foreign_keys) { to_foreign_keys(Gitlab::Database::PostgresForeignKey.by_constrained_table_name(table)) }
          let(:loose_foreign_keys) { Gitlab::Database::LooseForeignKeys.definitions.group_by(&:from_table).fetch(table, []) }
          let(:all_foreign_keys) { foreign_keys + loose_foreign_keys }
          let(:composite_primary_key) { Array.wrap(connection.primary_key(table)) }

          context 'all foreign keys' do
            # for index to be effective, the FK constraint has to be at first place
            it 'are indexed' do
              indexed_columns = indexes.filter_map do |index|
                columns = index.columns

                # In cases of complex composite indexes, a string is returned eg:
                # "lower((extern_uid)::text), group_id"
                columns = columns.split(',').map(&:chomp) if columns.is_a?(String)

                # A partial index is not suitable for a foreign key column, unless
                # the only condition is for the presence of the foreign key itself
                columns if index.where.nil? || index.where == "(#{columns.first} IS NOT NULL)"
              end
              foreign_keys_columns = all_foreign_keys.map(&:column)
              required_indexed_columns = to_columns(foreign_keys_columns - ignored_index_columns(table))

              # Add the composite primary key to the list of indexed columns because
              # postgres and mysql both automatically create an index on the primary
              # key. Also, the rails connection.indexes() method does not return
              # automatically generated indexes (like the primary key index).
              indexed_columns.push(composite_primary_key)

              expect(required_indexed_columns).to be_indexed_by(indexed_columns)
            end
          end

          context 'columns ending with _id' do
            let(:column_names) { columns.map(&:name) }
            let(:column_names_with_id) { column_names.select { |column_name| column_name.ends_with?('_id') } }
            let(:ignored_columns) { ignored_fk_columns(table) }
            let(:foreign_keys_columns) do
              to_columns(
                all_foreign_keys
                  .reject { |fk| fk.name&.end_with?("_id_convert_to_bigint") }
                  .map(&:column)
              )
            end

            it 'do have the foreign keys' do
              expect(column_names_with_id - ignored_columns).to be_a_foreign_key_column_of(foreign_keys_columns)
            end

            it 'and having foreign key are not in the ignore list' do
              expect(ignored_columns).to match_array(ignored_columns - foreign_keys)
            end
          end

          context 'btree indexes' do
            it 'only has existing indexes in the ignored duplicate indexes duplicate_indexes.yml' do
              table_ignored_indexes = (ignored_indexes[table] || {}).to_a.flatten.uniq
              indexes_by_name = indexes.map(&:name)
              expect(indexes_by_name).to include(*table_ignored_indexes)
            end

            it 'does not have any duplicated indexes' do
              duplicate_indexes = Database::DuplicateIndexes.new(table, indexes).duplicate_indexes
              expect(duplicate_indexes).to be_an_instance_of Hash

              table_ignored_indexes = ignored_indexes[table] || {}

              # We ignore all the indexes that are explicitly ignored in duplicate_indexes.yml
              duplicate_indexes.each do |index, matching_indexes|
                duplicate_indexes[index] = matching_indexes.reject do |matching_index|
                  table_ignored_indexes.fetch(index.name, []).include?(matching_index.name) ||
                    table_ignored_indexes.fetch(matching_index.name, []).include?(index.name)
                end

                duplicate_indexes.delete(index) if duplicate_indexes[index].empty?
              end

              if duplicate_indexes.present?
                btree_index = duplicate_indexes.each_key.first
                matching_indexes = duplicate_indexes[btree_index]

                error_message = <<~ERROR
                    Duplicate index: #{btree_index.name} with #{matching_indexes.map(&:name)}
                    #{btree_index.name} : #{btree_index.columns.inspect}
                    #{matching_indexes.first.name} : #{matching_indexes.first.columns.inspect}.
                    Consider dropping the indexes #{matching_indexes.map(&:name).join(', ')}
                ERROR
                raise error_message
              end
            end
          end
        end
      end
    end
  end

  # These pre-existing enums have limits > 2 bytes
  IGNORED_LIMIT_ENUMS = {
    'Analytics::CycleAnalytics::Stage' => %w[start_event_identifier end_event_identifier],
    'Ci::Bridge' => %w[failure_reason],
    'Ci::Build' => %w[failure_reason],
    'Ci::BuildMetadata' => %w[timeout_source],
    'Ci::BuildTraceChunk' => %w[data_store],
    'Ci::DailyReportResult' => %w[param_type],
    'Ci::JobArtifact' => %w[file_type],
    'Ci::Pipeline' => %w[source config_source failure_reason],
    'Ci::Processable' => %w[failure_reason],
    'Ci::Runner' => %w[access_level executor_type],
    'Ci::Stage' => %w[status],
    'Clusters::Cluster' => %w[platform_type provider_type],
    'CommitStatus' => %w[failure_reason],
    'GenericCommitStatus' => %w[failure_reason],
    'InternalId' => %w[usage],
    'List' => %w[list_type],
    'NotificationSetting' => %w[level],
    'Project' => %w[auto_cancel_pending_pipelines],
    'ProjectAutoDevops' => %w[deploy_strategy],
    'ResourceLabelEvent' => %w[action],
    'User' => %w[layout dashboard project_view],
    'Users::Callout' => %w[feature_name]
  }.freeze

  context 'for enums', :eager_load do
    # skip model if it is an abstract class as it would not have an associated DB table
    let(:models) { ApplicationRecord.descendants.reject(&:abstract_class?) }

    it 'uses smallint for enums in all models', :aggregate_failures do
      models.each do |model|
        ignored_enums = ignored_limit_enums(model.name)
        enums = model.defined_enums.keys - ignored_enums

        expect(model).to use_smallint_for_enums(enums)
      end
    end
  end

  # These pre-existing columns does not use a schema validation yet
  IGNORED_JSONB_COLUMNS = {
    "ApplicationSetting" => %w[repository_storages_weighted],
    "AlertManagement::Alert" => %w[payload],
    "Ci::BuildMetadata" => %w[config_options config_variables],
    "Ci::Runner" => %w[config],
    "ExperimentSubject" => %w[context],
    "ExperimentUser" => %w[context],
    "Geo::Event" => %w[payload],
    "GeoNodeStatus" => %w[status],
    "Operations::FeatureFlagScope" => %w[strategies],
    "Operations::FeatureFlags::Strategy" => %w[parameters],
    "Organizations::OrganizationSetting" => %w[settings], # Custom validations
    "Packages::Composer::Metadatum" => %w[composer_json],
    "RawUsageData" => %w[payload], # Usage data payload changes often, we cannot use one schema
    "Releases::Evidence" => %w[summary],
    "Vulnerabilities::Finding::Evidence" => %w[data], # Validation work in progress
    "Ai::DuoWorkflows::Checkpoint" => %w[checkpoint metadata], # https://gitlab.com/gitlab-org/gitlab/-/issues/468632
    "RemoteDevelopment::WorkspacesAgentConfigVersion" => %w[object object_changes] # Managed by paper_trail gem
  }.freeze

  # We are skipping GEO models for now as it adds up complexity
  describe 'for jsonb columns' do
    it 'uses json schema validator', :eager_load do
      columns_name_with_jsonb.each do |hash|
        next if models_by_table_name[hash["table_name"]].nil?

        models_by_table_name[hash["table_name"]].each do |model|
          # Skip migration models
          next if model.name.include?('Gitlab::BackgroundMigration')

          jsonb_columns = [hash["column_name"]] - ignored_jsonb_columns(model.name)
          expect(model).to validate_jsonb_schema(jsonb_columns)
        end
      end
    end
  end

  context 'existence of Postgres schemas' do
    def get_schemas
      sql = <<~SQL
        SELECT schema_name FROM
        information_schema.schemata
        WHERE
        NOT schema_name ~* '^pg_' AND NOT schema_name = 'information_schema'
        AND catalog_name = current_database()
      SQL

      ApplicationRecord.connection.select_all(sql).map do |row|
        row['schema_name']
      end
    end

    it 'we have a public schema' do
      expect(get_schemas).to include('public')
    end

    Gitlab::Database::EXTRA_SCHEMAS.each do |schema|
      it "we have a '#{schema}' schema'" do
        expect(get_schemas).to include(schema.to_s)
      end
    end

    it 'we do not have unexpected schemas' do
      expect(get_schemas.size).to eq(Gitlab::Database::EXTRA_SCHEMAS.size + 1)
    end
  end

  context 'primary keys' do
    it 'expects every table to have a primary key defined' do
      Gitlab::Database::EachDatabase.each_connection do |connection, _|
        schemas_for_connection = Gitlab::Database.gitlab_schemas_for_connection(connection)

        problematic_tables = connection.tables.select do |table|
          table_schema = Gitlab::Database::GitlabSchema.table_schema(table)
          schemas_for_connection.include?(table_schema) && !connection.primary_key(table).present?
        end.map(&:to_sym)

        expect(problematic_tables).to be_empty
      end
    end

    context 'for CI partitioned table' do
      # Check that each partitionable model with more than 1 column has the partition_id column at the trailing
      # position. Using .partitionable_models instead of iterating tables since when partitioning existing tables,
      # the routing table only gets created after the PK has already been created, which would be too late for a check.

      skip_tables = %w[]
      partitionable_models = Ci::Partitionable::Testing.partitionable_models
      (partitionable_models - skip_tables).each do |klass|
        model = klass.safe_constantize
        next unless model

        table_name = model.table_name

        primary_key_columns = Array.wrap(model.connection.primary_key(table_name))
        next if primary_key_columns.count == 1

        describe table_name do
          it 'expects every PK to have partition_id at trailing position' do
            expect(primary_key_columns).to match([an_instance_of(String), 'partition_id'])
          end
        end
      end
    end
  end

  context 'index names' do
    it 'disallows index names with a _ccnew[0-9]* suffix' do
      # During REINDEX operations, Postgres generates a temporary index with a _ccnew[0-9]* suffix
      # Since indexes are being considered temporary and subject to removal if they stick around for longer. See Gitlab::Database::Reindexing.
      #
      # Hence we disallow adding permanent indexes with this suffix.
      problematic_indexes = Gitlab::Database::PostgresIndex.match("#{Gitlab::Database::Reindexing::ReindexConcurrently::TEMPORARY_INDEX_PATTERN}$").all

      expect(problematic_indexes).to be_empty
    end
  end

  context 'ID columns' do
    it_behaves_like 'All IDs are bigint'
  end

  private

  def retrieve_columns_name_with_jsonb
    sql = <<~SQL
        SELECT table_name, column_name, data_type
          FROM information_schema.columns
        WHERE table_catalog = '#{ApplicationRecord.connection_db_config.database}'
          AND table_schema = 'public'
          AND table_name NOT LIKE 'pg_%'
          AND data_type = 'jsonb'
      ORDER BY table_name, column_name, data_type
    SQL

    ApplicationRecord.connection.select_all(sql).to_a
  end

  def to_foreign_keys(constraints)
    constraints.map do |constraint|
      from_table = constraint.constrained_table_identifier
      ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
        from_table,
        constraint.referenced_table_identifier,
        {
          name: constraint.name,
          column: constraint.constrained_columns,
          on_delete: constraint.on_delete_action&.to_sym,
          gitlab_schema: Gitlab::Database::GitlabSchema.table_schema!(from_table)
        }
      )
    end
  end

  def to_columns(items)
    items.map { |item| Array.wrap(item) }.uniq
  end

  def models_by_table_name
    @models_by_table_name ||= ApplicationRecord.descendants.reject(&:abstract_class).group_by(&:table_name)
  end

  def ignored_fk_columns(table)
    REMOVED_FKS.merge(IGNORED_FK_COLUMNS).fetch(table, [])
  end

  def ignored_index_columns(table)
    IGNORED_INDEXES_ON_FKS.fetch(table, [])
  end

  def ignored_limit_enums(model)
    IGNORED_LIMIT_ENUMS.fetch(model, [])
  end

  def ignored_jsonb_columns(model)
    IGNORED_JSONB_COLUMNS.fetch(model, [])
  end

  def ignored_indexes
    duplicate_indexes_file_path = "spec/support/helpers/database/duplicate_indexes.yml"
    @ignored_indexes ||= YAML.load_file(Rails.root.join(duplicate_indexes_file_path)) || {}
  end
end
