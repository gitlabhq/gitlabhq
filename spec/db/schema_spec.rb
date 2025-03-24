# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee/spec/db/schema_support') if Gitlab.ee?

RSpec.describe 'Database schema',
  # These skip a bit of unnecessary setup for each spec invocation,
  # and there are thousands of specs in this file. In total, this improves runtime by roughly 30%
  :do_not_mock_admin_mode_setting, :do_not_stub_snowplow_by_default,
  stackprof: { interval: 101000 },
  feature_category: :database do
  prepend_mod_with('DB::SchemaSupport')

  let(:tables) { connection.tables }
  let(:columns_name_with_jsonb) { retrieve_columns_name_with_jsonb }

  # If splitting FK and table removal into two MRs as suggested in the docs, use this constant in the initial FK removal MR.
  # In the subsequent table removal MR, remove the entries.
  # See: https://docs.gitlab.com/ee/development/migration_style_guide.html#dropping-a-database-table
  let(:removed_fks_map) do
    {
      # example_table: %w[example_column]
      alert_management_alerts: %w[prometheus_alert_id],
      search_namespace_index_assignments: [%w[search_index_id index_type]]
    }.with_indifferent_access.freeze
  end

  # List of columns historically missing a FK, don't add more columns
  # See: https://docs.gitlab.com/ee/development/database/foreign_keys.html#naming-foreign-keys
  let(:ignored_fk_columns_map) do
    {
      abuse_reports: %w[reporter_id user_id],
      abuse_report_notes: %w[discussion_id],
      ai_code_suggestion_events: %w[user_id],
      ai_duo_chat_events: %w[user_id organization_id],
      application_settings: %w[performance_bar_allowed_group_id slack_app_id snowplow_app_id eks_account_id
        eks_access_key_id],
      approvals: %w[user_id project_id],
      approver_groups: %w[target_id],
      approvers: %w[target_id user_id],
      analytics_cycle_analytics_aggregations: %w[last_full_issues_id last_full_merge_requests_id
        last_incremental_issues_id last_full_run_issues_id last_full_run_merge_requests_id
        last_incremental_merge_requests_id last_consistency_check_issues_stage_event_hash_id
        last_consistency_check_issues_issuable_id last_consistency_check_merge_requests_stage_event_hash_id
        last_consistency_check_merge_requests_issuable_id],
      analytics_cycle_analytics_merge_request_stage_events: %w[author_id group_id merge_request_id milestone_id
        project_id stage_event_hash_id state_id],
      analytics_cycle_analytics_issue_stage_events: %w[author_id group_id issue_id milestone_id project_id
        stage_event_hash_id state_id sprint_id],
      analytics_cycle_analytics_stage_aggregations: %w[last_issues_id last_merge_requests_id],
      analytics_cycle_analytics_stage_event_hashes: %w[organization_id],
      audit_events: %w[author_id entity_id target_id],
      approval_merge_request_rules_users: %w[project_id],
      user_audit_events: %w[author_id user_id target_id],
      group_audit_events: %w[author_id group_id target_id],
      project_audit_events: %w[author_id project_id target_id],
      instance_audit_events: %w[author_id target_id],
      award_emoji: %w[awardable_id user_id],
      aws_roles: %w[role_external_id],
      boards: %w[milestone_id iteration_id],
      broadcast_messages: %w[namespace_id],
      catalog_resource_component_last_usages: %w[used_by_project_id], # No FK constraint because we want to preserve usage data even if project is deleted.
      chat_names: %w[chat_id team_id user_id],
      chat_teams: %w[team_id],
      ci_builds: %w[project_id runner_id user_id erased_by_id trigger_request_id partition_id
        auto_canceled_by_partition_id execution_config_id upstream_pipeline_partition_id],
      ci_builds_metadata: %w[partition_id project_id build_id],
      ci_build_needs: %w[project_id],
      ci_build_pending_states: %w[project_id],
      ci_build_trace_chunks: %w[project_id],
      ci_builds_runner_session: %w[project_id],
      ci_daily_build_group_report_results: %w[partition_id],
      ci_deleted_objects: %w[project_id],
      ci_gitlab_hosted_runner_monthly_usages: %w[root_namespace_id project_id runner_id],
      ci_job_artifacts: %w[partition_id project_id job_id],
      ci_namespace_monthly_usages: %w[namespace_id],
      ci_pipeline_artifacts: %w[partition_id],
      ci_pipeline_chat_data: %w[partition_id project_id],
      ci_pipeline_messages: %w[partition_id project_id],
      ci_pipeline_metadata: %w[partition_id],
      ci_pipeline_schedule_variables: %w[project_id],
      ci_pipeline_variables: %w[partition_id pipeline_id project_id],
      ci_pipelines_config: %w[partition_id project_id],
      ci_pipelines: %w[partition_id auto_canceled_by_partition_id project_id user_id merge_request_id trigger_id], # LFKs are defined on the routing table
      ci_secure_file_states: %w[project_id],
      ci_unit_test_failures: %w[project_id],
      ci_resources: %w[project_id],
      p_ci_pipelines: %w[partition_id auto_canceled_by_partition_id auto_canceled_by_id trigger_id],
      p_ci_runner_machine_builds: %w[project_id],
      ci_runner_taggings: %w[runner_id sharding_key_id], # The sharding_key_id value is meant to populate the partitioned table, no other usage. The runner_id FK exists at the partition level
      ci_runner_taggings_instance_type: %w[sharding_key_id], # This field is always NULL in this partition
      ci_runners: %w[sharding_key_id], # This value is meant to populate the partitioned table, no other usage
      ci_runners_archived: %w[sharding_key_id creator_id], # This field is only used in the partitions, and has the appropriate FKs. We don't need the LFK for creator_id since that is already mirrored from ci_runners
      instance_type_ci_runners: %w[creator_id sharding_key_id], # No need for LFKs on partition, already handled on ci_runners routing table.
      group_type_ci_runners: %w[creator_id sharding_key_id], # No need for LFKs on partition, already handled on ci_runners routing table.
      project_type_ci_runners: %w[creator_id sharding_key_id], # No need for LFKs on partition, already handled on ci_runners routing table.
      ci_runner_machines: %w[runner_id sharding_key_id], # The runner_id and sharding_key_id fields are only used in the partitions, and have the appropriate FKs. The runner_id field will be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/503749.
      ci_runner_machines_archived: %w[runner_id sharding_key_id], # The sharding_key_id field is only used in the partitions, and has the appropriate FKs. The runner_id field will be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/503749.
      instance_type_ci_runner_machines: %w[sharding_key_id], # This field is always NULL in this partition.
      group_type_ci_runner_machines: %w[sharding_key_id], # No need for LFK, rows will be deleted by the FK to ci_runners.
      project_type_ci_runner_machines: %w[sharding_key_id], # No need for LFK, rows will be deleted by the FK to ci_runners.
      ci_runner_projects: %w[runner_id],
      ci_sources_pipelines: %w[partition_id source_partition_id source_job_id],
      ci_sources_projects: %w[partition_id],
      ci_stages: %w[partition_id project_id pipeline_id],
      ci_trigger_requests: %w[commit_id project_id],
      ci_job_artifact_states: %w[partition_id project_id],
      cluster_providers_aws: %w[security_group_id vpc_id access_key_id],
      cluster_providers_gcp: %w[gcp_project_id operation_id],
      compliance_management_frameworks: %w[group_id],
      commit_user_mentions: %w[commit_id],
      dast_site_profiles_builds: %w[project_id],
      dast_scanner_profiles_builds: %w[project_id],
      dast_profiles_pipelines: %w[project_id],
      dast_pre_scan_verification_steps: %w[project_id],
      dependency_list_export_parts: %w[start_id end_id],
      dep_ci_build_trace_sections: %w[build_id],
      deploy_keys_projects: %w[deploy_key_id],
      deployments: %w[deployable_id user_id],
      deployment_merge_requests: %w[project_id],
      description_versions: %w[namespace_id], # namespace_id will be added as an FK after backfill
      draft_notes: %w[discussion_id commit_id],
      epics: %w[updated_by_id last_edited_by_id state_id],
      events: %w[target_id],
      forked_project_links: %w[forked_from_project_id],
      geo_node_statuses: %w[last_event_id cursor_last_event_id],
      geo_nodes: %w[oauth_application_id],
      geo_repository_deleted_events: %w[project_id],
      ghost_user_migrations: %w[initiator_user_id],
      gitlab_subscription_histories: %w[gitlab_subscription_id hosted_plan_id namespace_id],
      identities: %w[user_id],
      import_failures: %w[project_id],
      issues: %w[last_edited_by_id state_id work_item_type_id],
      issue_emails: %w[email_message_id],
      jira_tracker_data: %w[jira_issue_transition_id],
      keys: %w[user_id],
      label_links: %w[target_id],
      ldap_group_links: %w[group_id],
      members: %w[source_id created_by_id],
      merge_requests: %w[last_edited_by_id state_id],
      merge_request_cleanup_schedules: %w[project_id],
      merge_requests_compliance_violations: %w[target_project_id],
      merge_request_diffs: %w[project_id],
      merge_request_diff_files: %w[project_id],
      merge_request_diff_commits: %w[commit_author_id committer_id],
      # merge_request_diff_commits_b5377a7a34 is the temporary table for the merge_request_diff_commits partitioning
      # backfill. It will get foreign keys after the partitioning is finished.
      merge_request_diff_commits_b5377a7a34: %w[merge_request_diff_id commit_author_id committer_id project_id],
      namespaces: %w[owner_id parent_id],
      namespace_descendants: %w[namespace_id],
      notes: %w[author_id commit_id noteable_id updated_by_id resolved_by_id confirmed_by_id discussion_id],
      notification_settings: %w[source_id],
      oauth_access_grants: %w[resource_owner_id application_id],
      oauth_access_tokens: %w[resource_owner_id application_id],
      oauth_applications: %w[owner_id],
      oauth_device_grants: %w[resource_owner_id application_id],
      packages_nuget_symbols: %w[project_id],
      packages_package_files: %w[project_id],
      p_ci_builds: %w[erased_by_id trigger_request_id partition_id auto_canceled_by_partition_id execution_config_id
        upstream_pipeline_partition_id],
      p_ci_builds_metadata: %w[project_id build_id partition_id],
      p_ci_build_trace_metadata: %w[project_id],
      p_batched_git_ref_updates_deletions: %w[project_id partition_id],
      p_catalog_resource_sync_events: %w[catalog_resource_id project_id partition_id],
      p_catalog_resource_component_usages: %w[used_by_project_id], # No FK constraint because we want to preserve historical usage data
      p_ci_finished_build_ch_sync_events: %w[build_id],
      p_ci_finished_pipeline_ch_sync_events: %w[pipeline_id project_namespace_id],
      p_ci_job_annotations: %w[partition_id job_id project_id],
      p_ci_job_artifacts: %w[partition_id project_id job_id],
      p_ci_pipeline_variables: %w[partition_id pipeline_id project_id],
      p_ci_pipelines_config: %w[partition_id project_id],
      p_ci_builds_execution_configs: %w[partition_id],
      p_ci_stages: %w[partition_id project_id pipeline_id],
      project_build_artifacts_size_refreshes: %w[last_job_artifact_id],
      project_data_transfers: %w[project_id namespace_id],
      project_error_tracking_settings: %w[sentry_project_id],
      project_statistics: %w[namespace_id],
      projects: %w[ci_id mirror_user_id],
      push_event_payloads: %w[project_id],
      redirect_routes: %w[source_id],
      repository_languages: %w[programming_language_id],
      routes: %w[source_id],
      security_findings: %w[project_id],
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
      uploads: %w[model_id organization_id namespace_id project_id],
      uploads_9ba88c4165: %w[model_id],
      abuse_report_uploads: %w[model_id],
      achievement_uploads: %w[model_id],
      ai_vectorizable_file_uploads: %w[model_id],
      alert_management_alert_metric_image_uploads: %w[model_id],
      appearance_uploads: %w[model_id],
      bulk_import_export_upload_uploads: %w[model_id],
      dependency_list_export_part_uploads: %w[model_id],
      dependency_list_export_uploads: %w[model_id],
      design_management_action_uploads: %w[model_id],
      import_export_upload_uploads: %w[model_id],
      issuable_metric_image_uploads: %w[model_id],
      namespace_uploads: %w[model_id],
      note_uploads: %w[model_id],
      organization_detail_uploads: %w[model_id],
      project_import_export_relation_export_upload_uploads: %w[model_id],
      project_topic_uploads: %w[model_id],
      project_uploads: %w[model_id],
      snippet_uploads: %w[model_id],
      user_permission_export_upload_uploads: %w[model_id],
      user_uploads: %w[model_id],
      vulnerability_export_part_uploads: %w[model_id],
      vulnerability_export_uploads: %w[model_id],
      vulnerability_archive_export_uploads: %w[model_id],
      vulnerability_remediation_uploads: %w[model_id],
      user_agent_details: %w[subject_id],
      users: %w[color_mode_id color_scheme_id created_by_id theme_id managing_group_id accepted_term_id],
      users_star_projects: %w[user_id],
      vulnerability_finding_links: %w[project_id],
      vulnerability_identifiers: %w[external_id],
      vulnerability_occurrence_identifiers: %w[project_id],
      vulnerability_scanners: %w[external_id],
      security_scans: %w[pipeline_id project_id], # foreign key is not added as ci_pipeline table will be moved into different db soon
      dependency_list_exports: %w[pipeline_id], # foreign key is not added as ci_pipeline table is in different db
      vulnerability_reads: %w[cluster_agent_id namespace_id], # namespace_id is a denormalization of `project.namespace`
      # See: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87584
      # Fixes performance issues with the deletion of web-hooks with many log entries
      web_hook_logs: %w[web_hook_id],
      web_hook_logs_daily: %w[web_hook_id],
      webauthn_registrations: %w[u2f_registration_id], # this column will be dropped
      ml_candidates: %w[internal_id],
      value_stream_dashboard_counts: %w[namespace_id],
      vulnerability_export_parts: %w[start_id end_id],
      zoekt_indices: %w[namespace_id], # needed for cells sharding key
      zoekt_repositories: %w[namespace_id project_identifier], # needed for cells sharding key
      zoekt_tasks: %w[project_identifier partition_id zoekt_repository_id zoekt_node_id], # needed for: cells sharding key, partitioning, and performance reasons
      # TODO: To remove with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155256
      approval_group_rules: %w[approval_policy_rule_id],
      approval_project_rules: %w[approval_policy_rule_id],
      approval_merge_request_rules: %w[approval_policy_rule_id],
      scan_result_policy_violations: %w[approval_policy_rule_id],
      software_license_policies: %w[approval_policy_rule_id],
      ai_testing_terms_acceptances: %w[user_id], # testing terms only have 1 entry, and if the user is deleted the record should remain
      namespace_settings: %w[early_access_program_joined_by_id], # isn't used inside product itself. Only through Snowflake
      workspaces_agent_config_versions: %w[item_id], # polymorphic associations
      work_item_types: %w[correct_id old_id], # temporary columns that are not foreign keys
      instance_integrations: %w[project_id group_id inherit_from_id], # these columns are not used in instance integrations
      group_scim_identities: %w[temp_source_id], # temporary column that is not a foreign key
      group_scim_auth_access_tokens: %w[temp_source_id], # temporary column that is not a foreign key
      secret_detection_token_statuses: %w[project_id],
      system_access_group_microsoft_graph_access_tokens: %w[temp_source_id], # temporary column that is not a foreign key
      system_access_group_microsoft_applications: %w[temp_source_id], # temporary column that is not a foreign key
      subscription_user_add_on_assignment_versions: %w[item_id user_id purchase_id], # Managed by paper_trail gem, no need for FK on the historical data
      virtual_registries_packages_maven_cache_entries: %w[group_id], # We can't use a foreign key due to object storage references
      # system_defined_status_id reference to fixed items model which is stored in code
      # custom_status_id to be implemented association, column exists for better column ordering
      # TODO: Remove custom_status_id https://gitlab.com/gitlab-org/gitlab/-/work_items/520312
      work_item_current_statuses: %w[system_defined_status_id custom_status_id]
    }.with_indifferent_access.freeze
  end

  let(:ignored_tables_with_too_many_indexes) do
    {
      approval_merge_request_rules: 17,
      ci_builds: 27,
      ci_pipelines: 24,
      ci_runners: 16,
      ci_runners_archived: 17,
      deployments: 18,
      epics: 19,
      events: 16,
      group_type_ci_runners: 17,
      instance_type_ci_runners: 17,
      issues: 39,
      members: 21,
      merge_requests: 33,
      namespaces: 26,
      p_ci_builds: 27,
      p_ci_pipelines: 24,
      packages_package_files: 16,
      packages_packages: 27,
      project_type_ci_runners: 17,
      projects: 55,
      sbom_occurrences: 25,
      users: 32,
      vulnerability_reads: 23
    }.with_indifferent_access.freeze
  end

  # For partitioned CI references we do not require a composite index starting with `partition_id` as each partition
  # only contains records with a single `partition_id`. As such the index on the other id in the foreign key will be
  # sufficient.
  def ci_partitioned_foreign_key?(foreign_key)
    target = foreign_key.to_table.split('.').last
    schema = Gitlab::Database::GitlabSchema.table_schema!(target)
    schema == :gitlab_ci &&
      Array.wrap(foreign_key.column).many? &&
      foreign_key.column.first.end_with?('partition_id')
  end

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
          let(:loose_foreign_keys) do
            Gitlab::Database::LooseForeignKeys.definitions.group_by(&:from_table).fetch(table, [])
          end

          let(:all_foreign_keys) { foreign_keys + loose_foreign_keys }
          let(:composite_primary_key) { Array.wrap(connection.primary_key(table)) }

          context 'with all foreign keys' do
            # for index to be effective, the FK constraint has to be at first place
            it 'are indexed', :aggregate_failures do
              indexed_columns = indexes.filter_map do |index|
                columns = index.columns

                # In cases of complex composite indexes, a string is returned eg:
                # "lower((extern_uid)::text), group_id"
                columns = columns.split(',').map(&:chomp) if columns.is_a?(String)

                # A partial index is not suitable for a foreign key column, unless
                # the only condition is for the presence of the foreign key itself
                columns if index.where.nil? || index.where == "(#{columns.first} IS NOT NULL)"
              end

              required_indexed_foreign_keys = all_foreign_keys.reject do |fk|
                ci_partitioned_foreign_key?(fk) ||
                  fk.options[:conditions]&.any?
              end

              # Add the composite primary key to the list of indexed columns because
              # postgres and mysql both automatically create an index on the primary
              # key. Also, the rails connection.indexes() method does not return
              # automatically generated indexes (like the primary key index).
              indexed_columns.push(composite_primary_key)

              required_indexed_foreign_keys.each do |required_indexed_foreign_key| # rubocop:disable RSpec/IteratedExpectation -- We want to aggregate all failures
                expect(required_indexed_foreign_key).to be_indexed_by(indexed_columns)
              end
            end
          end

          context 'with columns ending with _id' do
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

          context 'with btree indexes' do
            it 'only has existing indexes in the ignored duplicate indexes duplicate_indexes.yml' do
              table_ignored_indexes = (ignored_indexes[table] || {}).to_a.flatten.uniq
              indexes_by_name = indexes.map(&:name)
              expect(indexes_by_name).to include(*table_ignored_indexes) unless table_ignored_indexes.empty?
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

  context 'for enums', :eager_load do
    # These pre-existing enums have limits > 2 bytes
    let(:ignored_limit_enums_map) do
      {
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
        'Users::Callout' => %w[feature_name],
        'Vulnerability' => %w[confidence] # this enum is in the process of being deprecated
      }.freeze
    end

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

  # We are skipping GEO models for now as it adds up complexity
  describe 'for jsonb columns' do
    # These pre-existing columns does not use a schema validation yet
    let(:ignored_jsonb_columns_map) do
      {
        "Ai::Conversation::Message" => %w[extras error_details],
        "Ai::DuoWorkflows::Checkpoint" => %w[checkpoint metadata], # https://gitlab.com/gitlab-org/gitlab/-/issues/468632
        "ApplicationSetting" => %w[repository_storages_weighted oauth_provider rate_limits_unauthenticated_git_http],
        "AlertManagement::Alert" => %w[payload],
        "AlertManagement::HttpIntegration" => %w[payload_example],
        "Ci::BuildMetadata" => %w[config_options config_variables runtime_runner_features],
        "Ci::Runner" => %w[config],
        "ExperimentSubject" => %w[context],
        "ExperimentUser" => %w[context],
        "Geo::Event" => %w[payload],
        "GeoNodeStatus" => %w[status],
        "GitlabSubscriptions::UserAddOnAssignmentVersion" => %w[object], # Managed by paper_trail gem
        "Operations::FeatureFlagScope" => %w[strategies],
        "Operations::FeatureFlags::Strategy" => %w[parameters],
        "Organizations::OrganizationSetting" => %w[settings], # Custom validations
        "Packages::Composer::Metadatum" => %w[composer_json],
        "RawUsageData" => %w[payload], # Usage data payload changes often, we cannot use one schema
        "Sbom::Occurrence" => %w[ancestors],
        "Security::ApprovalPolicyRule" => %w[content],
        "Security::Policy" => %w[metadata],
        "ServicePing::NonSqlServicePing" => %w[payload], # Usage data payload changes often, we cannot use one schema
        "ServicePing::QueriesServicePing" => %w[payload], # Usage data payload changes often, we cannot use one schema
        "Security::ScanExecutionPolicyRule" => %w[content],
        "Security::VulnerabilityManagementPolicyRule" => %w[content],
        "Releases::Evidence" => %w[summary],
        "RemoteDevelopment::WorkspacesAgentConfigVersion" => %w[object object_changes], # Managed by paper_trail gem
        "RemoteDevelopment::WorkspacesAgentConfig" => %w[annotations labels],
        "RemoteDevelopment::RemoteDevelopmentAgentConfig" => %w[annotations image_pull_secrets labels],
        "Vulnerabilities::Finding" => %w[location],
        "Vulnerabilities::Finding::Evidence" => %w[data] # Validation work in progress
      }.freeze
    end

    def failure_message(model, column)
      <<~FAILURE_MESSAGE
              Expected #{model.name} to validate the schema of #{column}.

              Use JsonSchemaValidator in your model when using a jsonb column.
              See doc/development/migration_style_guide.html#storing-json-in-database for more information.

              To fix this, please add `validates :#{column}, json_schema: { filename: "filename" }` in your model file, for example:

              class #{model.name}
                validates :#{column}, json_schema: { filename: "filename" }
              end
      FAILURE_MESSAGE
    end

    it 'uses json schema validator', :eager_load, :aggregate_failures, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/500903' do
      columns_name_with_jsonb.each do |jsonb_column|
        column_name = jsonb_column["column_name"]
        models = models_by_table_name[jsonb_column["table_name"]] || []

        models.each do |model|
          # Skip migration models
          next if model.name.include?('Gitlab::BackgroundMigration')
          next if ignored_jsonb_columns(model.name).include?(column_name)

          has_validator = model.validators.any? do |v|
            v.is_a?(JsonSchemaValidator) && v.attributes.include?(column_name.to_sym)
          end

          expect(has_validator).to be(true), failure_message(model, column_name)
        end
      end
    end
  end

  context 'with existence of Postgres schemas' do
    let_it_be(:schemas) do
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
      expect(schemas).to include('public')
    end

    Gitlab::Database::EXTRA_SCHEMAS.each do |schema|
      it "we have a '#{schema}' schema'" do
        expect(schemas).to include(schema.to_s)
      end
    end

    it 'we do not have unexpected schemas' do
      expect(schemas.size).to eq(Gitlab::Database::EXTRA_SCHEMAS.size + 1)
    end
  end

  context 'with primary keys' do
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

  context 'with indexes' do
    it 'disallows index names with a _ccnew[0-9]* suffix' do
      # During REINDEX operations, Postgres generates a temporary index with a _ccnew[0-9]* suffix
      # Since indexes are being considered temporary and subject to removal if they stick around for longer.
      # See Gitlab::Database::Reindexing.
      #
      # Hence we disallow adding permanent indexes with this suffix.
      problematic_indexes = Gitlab::Database::PostgresIndex.match(
        "#{Gitlab::Database::Reindexing::ReindexConcurrently::TEMPORARY_INDEX_PATTERN}$").all

      expect(problematic_indexes).to be_empty
    end

    context 'when exceeding the authorized limit' do
      let(:max) { Gitlab::Database::MAX_INDEXES_ALLOWED_PER_TABLE }
      let!(:known_offences) { ignored_tables_with_too_many_indexes }
      let!(:corrected_offences) { known_offences.keys.to_set - actual_offences.keys.to_set }
      let!(:new_offences) { actual_offences.keys.to_set - known_offences.keys.to_set }
      let!(:actual_offences) do
        Gitlab::Database::PostgresIndex
          .where(schema: 'public')
          .group(:tablename)
          .having("COUNT(*) > #{max}")
          .count
      end

      it 'checks for corrected_offences' do
        expect(corrected_offences).to validate_index_limit(:corrected)
      end

      it 'checks for new_offences' do
        expect(new_offences).to validate_index_limit(:new)
      end

      it 'checks for outdated_offences' do
        outdated_offences = known_offences.filter_map do |table, expected|
          actual = actual_offences[table]

          "#{table} (expected #{expected}, actual #{actual})" if actual && expected != actual
        end

        expect(outdated_offences).to validate_index_limit(:outdated)
      end
    end
  end

  context 'with ID columns' do
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
    removed_fks_map.merge(ignored_fk_columns_map).fetch(table, [])
  end

  def ignored_limit_enums(model)
    ignored_limit_enums_map.fetch(model, [])
  end

  def ignored_jsonb_columns(model)
    ignored_jsonb_columns_map.fetch(model, [])
  end

  def ignored_indexes
    duplicate_indexes_file_path = "spec/support/helpers/database/duplicate_indexes.yml"
    @ignored_indexes ||= YAML.load_file(Rails.root.join(duplicate_indexes_file_path)) || {}
  end
end
