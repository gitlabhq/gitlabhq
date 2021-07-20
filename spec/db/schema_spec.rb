# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'spec', 'db', 'schema_support') if Gitlab.ee?

RSpec.describe 'Database schema' do
  prepend_mod_with('DB::SchemaSupport')

  let(:connection) { ActiveRecord::Base.connection }
  let(:tables) { connection.tables }
  let(:columns_name_with_jsonb) { retrieve_columns_name_with_jsonb }

  # List of columns historically missing a FK, don't add more columns
  # See: https://docs.gitlab.com/ee/development/foreign_keys.html#naming-foreign-keys
  IGNORED_FK_COLUMNS = {
    abuse_reports: %w[reporter_id user_id],
    application_settings: %w[performance_bar_allowed_group_id slack_app_id snowplow_app_id eks_account_id eks_access_key_id],
    approvals: %w[user_id],
    approver_groups: %w[target_id],
    approvers: %w[target_id user_id],
    audit_events: %w[author_id entity_id target_id],
    award_emoji: %w[awardable_id user_id],
    aws_roles: %w[role_external_id],
    boards: %w[milestone_id iteration_id],
    chat_names: %w[chat_id team_id user_id],
    chat_teams: %w[team_id],
    ci_builds: %w[erased_by_id runner_id trigger_request_id user_id],
    ci_namespace_monthly_usages: %w[namespace_id],
    ci_pipelines: %w[user_id],
    ci_runner_projects: %w[runner_id],
    ci_trigger_requests: %w[commit_id],
    cluster_providers_aws: %w[security_group_id vpc_id access_key_id],
    cluster_providers_gcp: %w[gcp_project_id operation_id],
    compliance_management_frameworks: %w[group_id],
    commit_user_mentions: %w[commit_id],
    deploy_keys_projects: %w[deploy_key_id],
    deployments: %w[deployable_id user_id],
    draft_notes: %w[discussion_id commit_id],
    epics: %w[updated_by_id last_edited_by_id state_id],
    events: %w[target_id],
    forked_project_links: %w[forked_from_project_id],
    geo_event_log: %w[hashed_storage_attachments_event_id],
    geo_job_artifact_deleted_events: %w[job_artifact_id],
    geo_lfs_object_deleted_events: %w[lfs_object_id],
    geo_node_statuses: %w[last_event_id cursor_last_event_id],
    geo_nodes: %w[oauth_application_id],
    geo_repository_deleted_events: %w[project_id],
    geo_upload_deleted_events: %w[upload_id model_id],
    gitlab_subscription_histories: %w[gitlab_subscription_id hosted_plan_id namespace_id],
    identities: %w[user_id],
    import_failures: %w[project_id],
    issues: %w[last_edited_by_id state_id],
    jira_tracker_data: %w[jira_issue_transition_id],
    keys: %w[user_id],
    label_links: %w[target_id],
    ldap_group_links: %w[group_id],
    members: %w[source_id created_by_id],
    merge_requests: %w[last_edited_by_id state_id],
    merge_request_diff_commits: %w[commit_author_id committer_id],
    namespaces: %w[owner_id parent_id],
    notes: %w[author_id commit_id noteable_id updated_by_id resolved_by_id confirmed_by_id discussion_id],
    notification_settings: %w[source_id],
    oauth_access_grants: %w[resource_owner_id application_id],
    oauth_access_tokens: %w[resource_owner_id application_id],
    oauth_applications: %w[owner_id],
    open_project_tracker_data: %w[closed_status_id],
    product_analytics_events_experimental: %w[event_id txn_id user_id],
    project_group_links: %w[group_id],
    project_statistics: %w[namespace_id],
    projects: %w[creator_id ci_id mirror_user_id],
    redirect_routes: %w[source_id],
    repository_languages: %w[programming_language_id],
    routes: %w[source_id],
    sent_notifications: %w[project_id noteable_id recipient_id commit_id in_reply_to_discussion_id],
    slack_integrations: %w[team_id user_id],
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
    users: %w[color_scheme_id created_by_id theme_id email_opted_in_source_id],
    users_star_projects: %w[user_id],
    vulnerability_identifiers: %w[external_id],
    vulnerability_scanners: %w[external_id]
  }.with_indifferent_access.freeze

  context 'for table' do
    ActiveRecord::Base.connection.tables.sort.each do |table|
      describe table do
        let(:indexes) { connection.indexes(table) }
        let(:columns) { connection.columns(table) }
        let(:foreign_keys) { connection.foreign_keys(table) }
        # take the first column in case we're using a composite primary key
        let(:primary_key_column) { Array(connection.primary_key(table)).first }

        context 'all foreign keys' do
          # for index to be effective, the FK constraint has to be at first place
          it 'are indexed' do
            first_indexed_column = indexes.map(&:columns).map do |columns|
              # In cases of complex composite indexes, a string is returned eg:
              # "lower((extern_uid)::text), group_id"
              columns = columns.split(',') if columns.is_a?(String)
              columns.first.chomp
            end
            foreign_keys_columns = foreign_keys.map(&:column)

            # Add the primary key column to the list of indexed columns because
            # postgres and mysql both automatically create an index on the primary
            # key. Also, the rails connection.indexes() method does not return
            # automatically generated indexes (like the primary key index).
            first_indexed_column.push(primary_key_column)

            expect(first_indexed_column.uniq).to include(*foreign_keys_columns)
          end
        end

        context 'columns ending with _id' do
          let(:column_names) { columns.map(&:name) }
          let(:column_names_with_id) { column_names.select { |column_name| column_name.ends_with?('_id') } }
          let(:foreign_keys_columns) { foreign_keys.map(&:column) }
          let(:ignored_columns) { ignored_fk_columns(table) }

          it 'do have the foreign keys' do
            expect(column_names_with_id - ignored_columns).to match_array(foreign_keys_columns)
          end

          it 'and having foreign key are not in the ignore list' do
            expect(ignored_columns).to match_array(ignored_columns - foreign_keys)
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
    'Ci::DailyReportResult' => %w[param_type],
    'Ci::JobArtifact' => %w[file_type],
    'Ci::Pipeline' => %w[source config_source failure_reason],
    'Ci::Processable' => %w[failure_reason],
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
      # skip model if it is an abstract class as it would not have an associated DB table
      next if model.abstract_class?

      describe model do
        let(:ignored_enums) { ignored_limit_enums(model.name) }
        let(:enums) { model.defined_enums.keys - ignored_enums }

        it 'uses smallint for enums' do
          expect(model).to use_smallint_for_enums(enums)
        end
      end
    end
  end

  # These pre-existing columns does not use a schema validation yet
  IGNORED_JSONB_COLUMNS = {
    "ApplicationSetting" => %w[repository_storages_weighted],
    "AlertManagement::Alert" => %w[payload],
    "Ci::BuildMetadata" => %w[config_options config_variables],
    "ExperimentSubject" => %w[context],
    "ExperimentUser" => %w[context],
    "Geo::Event" => %w[payload],
    "GeoNodeStatus" => %w[status],
    "Operations::FeatureFlagScope" => %w[strategies],
    "Operations::FeatureFlags::Strategy" => %w[parameters],
    "Packages::Composer::Metadatum" => %w[composer_json],
    "RawUsageData" => %w[payload], # Usage data payload changes often, we cannot use one schema
    "Releases::Evidence" => %w[summary]
  }.freeze

  # We are skipping GEO models for now as it adds up complexity
  describe 'for jsonb columns' do
    it 'uses json schema validator' do
      columns_name_with_jsonb.each do |hash|
        next if models_by_table_name[hash["table_name"]].nil?

        models_by_table_name[hash["table_name"]].each do |model|
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
    let(:exceptions) do
      %i(
        elasticsearch_indexed_namespaces
        elasticsearch_indexed_projects
        merge_request_context_commit_diff_files
      )
    end

    it 'expects every table to have a primary key defined' do
      connection = ActiveRecord::Base.connection

      problematic_tables = connection.tables.select do |table|
        !connection.primary_key(table).present?
      end.map(&:to_sym)

      expect(problematic_tables - exceptions).to be_empty
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

  def models_by_table_name
    @models_by_table_name ||= ApplicationRecord.descendants.reject(&:abstract_class).group_by(&:table_name)
  end

  def ignored_fk_columns(column)
    IGNORED_FK_COLUMNS.fetch(column, [])
  end

  def ignored_limit_enums(model)
    IGNORED_LIMIT_ENUMS.fetch(model, [])
  end

  def ignored_jsonb_columns(model)
    IGNORED_JSONB_COLUMNS.fetch(model, [])
  end
end
