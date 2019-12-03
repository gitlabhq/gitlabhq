# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'spec', 'db', 'schema_support') if Gitlab.ee?

describe 'Database schema' do
  prepend_if_ee('EE::DB::SchemaSupport')

  let(:connection) { ActiveRecord::Base.connection }
  let(:tables) { connection.tables }

  # Use if you are certain that this column should not have a foreign key
  # EE: edit the ee/spec/db/schema_support.rb
  IGNORED_FK_COLUMNS = {
    abuse_reports: %w[reporter_id user_id],
    application_settings: %w[performance_bar_allowed_group_id slack_app_id snowplow_app_id eks_account_id eks_access_key_id],
    approvers: %w[target_id user_id],
    approvals: %w[user_id],
    approver_groups: %w[target_id],
    audit_events: %w[author_id entity_id],
    award_emoji: %w[awardable_id user_id],
    aws_roles: %w[role_external_id],
    boards: %w[milestone_id],
    chat_names: %w[chat_id service_id team_id user_id],
    chat_teams: %w[team_id],
    ci_builds: %w[erased_by_id runner_id trigger_request_id user_id],
    ci_pipelines: %w[user_id],
    ci_runner_projects: %w[runner_id],
    ci_trigger_requests: %w[commit_id],
    cluster_providers_aws: %w[security_group_id vpc_id access_key_id],
    cluster_providers_gcp: %w[gcp_project_id operation_id],
    deploy_keys_projects: %w[deploy_key_id],
    deployments: %w[deployable_id environment_id user_id],
    draft_notes: %w[discussion_id commit_id],
    emails: %w[user_id],
    events: %w[target_id],
    epics: %w[updated_by_id last_edited_by_id start_date_sourcing_milestone_id due_date_sourcing_milestone_id state_id],
    forked_project_links: %w[forked_from_project_id],
    geo_event_log: %w[hashed_storage_attachments_event_id],
    geo_job_artifact_deleted_events: %w[job_artifact_id],
    geo_lfs_object_deleted_events: %w[lfs_object_id],
    geo_node_statuses: %w[last_event_id cursor_last_event_id],
    geo_nodes: %w[oauth_application_id],
    geo_repository_deleted_events: %w[project_id],
    geo_upload_deleted_events: %w[upload_id model_id],
    import_failures: %w[project_id],
    identities: %w[user_id],
    issues: %w[last_edited_by_id state_id],
    jira_tracker_data: %w[jira_issue_transition_id],
    keys: %w[user_id],
    label_links: %w[target_id],
    lfs_objects_projects: %w[lfs_object_id project_id],
    ldap_group_links: %w[group_id],
    members: %w[source_id created_by_id],
    merge_requests: %w[last_edited_by_id state_id],
    namespaces: %w[owner_id parent_id],
    notes: %w[author_id commit_id noteable_id updated_by_id resolved_by_id discussion_id],
    notification_settings: %w[source_id],
    oauth_access_grants: %w[resource_owner_id application_id],
    oauth_access_tokens: %w[resource_owner_id application_id],
    oauth_applications: %w[owner_id],
    project_group_links: %w[group_id],
    project_statistics: %w[namespace_id],
    projects: %w[creator_id namespace_id ci_id mirror_user_id],
    redirect_routes: %w[source_id],
    repository_languages: %w[programming_language_id],
    routes: %w[source_id],
    sent_notifications: %w[project_id noteable_id recipient_id commit_id in_reply_to_discussion_id],
    snippets: %w[author_id],
    spam_logs: %w[user_id],
    subscriptions: %w[user_id subscribable_id],
    slack_integrations: %w[team_id user_id],
    taggings: %w[tag_id taggable_id tagger_id],
    timelogs: %w[user_id],
    todos: %w[target_id commit_id],
    uploads: %w[model_id],
    user_agent_details: %w[subject_id],
    users: %w[color_scheme_id created_by_id theme_id email_opted_in_source_id],
    users_star_projects: %w[user_id],
    vulnerability_identifiers: %w[external_id],
    vulnerability_scanners: %w[external_id],
    web_hooks: %w[service_id group_id],
    suggestions: %w[commit_id],
    commit_user_mentions: %w[commit_id]
  }.with_indifferent_access.freeze

  context 'for table' do
    ActiveRecord::Base.connection.tables.sort.each do |table|
      describe table do
        let(:indexes) { connection.indexes(table) }
        let(:columns) { connection.columns(table) }
        let(:foreign_keys) { connection.foreign_keys(table) }
        let(:primary_key_column) { connection.primary_key(table) }

        context 'all foreign keys' do
          # for index to be effective, the FK constraint has to be at first place
          it 'are indexed' do
            first_indexed_column = indexes.map(&:columns).map(&:first)
            foreign_keys_columns = foreign_keys.map(&:column)

            # Add the primary key column to the list of indexed columns because
            # postgres and mysql both automatically create an index on the primary
            # key. Also, the rails connection.indexes() method does not return
            # automatically generated indexes (like the primary key index).
            first_indexed_column = first_indexed_column.push(primary_key_column)

            expect(first_indexed_column.uniq).to include(*foreign_keys_columns)
          end
        end

        context 'columns ending with _id' do
          let(:column_names) { columns.map(&:name) }
          let(:column_names_with_id) { column_names.select { |column_name| column_name.ends_with?('_id') } }
          let(:foreign_keys_columns) { foreign_keys.map(&:column) }
          let(:ignored_columns) { ignored_fk_columns(table) }

          it 'do have the foreign keys' do
            expect(column_names_with_id - ignored_columns).to contain_exactly(*foreign_keys_columns)
          end
        end
      end
    end
  end

  # These pre-existing enums have limits > 2 bytes
  IGNORED_LIMIT_ENUMS = {
    'Analytics::CycleAnalytics::GroupStage' => %w[start_event_identifier end_event_identifier],
    'Analytics::CycleAnalytics::ProjectStage' => %w[start_event_identifier end_event_identifier],
    'Ci::Bridge' => %w[failure_reason],
    'Ci::Build' => %w[failure_reason],
    'Ci::BuildMetadata' => %w[timeout_source],
    'Ci::BuildTraceChunk' => %w[data_store],
    'Ci::JobArtifact' => %w[file_type],
    'Ci::Pipeline' => %w[source config_source failure_reason],
    'Ci::Runner' => %w[access_level],
    'Ci::Stage' => %w[status],
    'Clusters::Applications::Ingress' => %w[ingress_type],
    'Clusters::Cluster' => %w[platform_type provider_type],
    'CommitStatus' => %w[failure_reason],
    'GenericCommitStatus' => %w[failure_reason],
    'Gitlab::DatabaseImporters::CommonMetrics::PrometheusMetric' => %w[group],
    'InternalId' => %w[usage],
    'List' => %w[list_type],
    'NotificationSetting' => %w[level],
    'Project' => %w[auto_cancel_pending_pipelines],
    'ProjectAutoDevops' => %w[deploy_strategy],
    'PrometheusMetric' => %w[group],
    'ResourceLabelEvent' => %w[action],
    'User' => %w[layout dashboard project_view],
    'UserCallout' => %w[feature_name],
    'PrometheusAlert' => %w[operator]
  }.freeze

  context 'for enums' do
    ApplicationRecord.descendants.each do |model|
      describe model do
        let(:ignored_enums) { ignored_limit_enums(model.name) }
        let(:enums) { model.defined_enums.keys - ignored_enums }

        it 'uses smallint for enums' do
          expect(model).to use_smallint_for_enums(enums)
        end
      end
    end
  end

  private

  def ignored_fk_columns(column)
    IGNORED_FK_COLUMNS.fetch(column, [])
  end

  def ignored_limit_enums(model)
    IGNORED_LIMIT_ENUMS.fetch(model, [])
  end
end
