# frozen_string_literal: true

# When developing usage data metrics use the below usage data interface methods
# unless you have good reasons to implement custom usage data
# See `lib/gitlab/utils/usage_data.rb`
#
# Examples
#   issues_using_zoom_quick_actions: distinct_count(ZoomMeeting, :issue_id),
#   active_user_count: count(User.active)
#   alt_usage_data { Gitlab::VERSION }
#   redis_usage_data(Gitlab::UsageDataCounters::WikiPageCounter)
#   redis_usage_data { Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: 'users_expanding_vulnerabilities', start_date: 28.days.ago, end_date: Date.current) }

# NOTE:
# Implementing metrics direct in `usage_data.rb` is deprecated,
# please add new instrumentation class and use add_metric method.
# For more information, see https://docs.gitlab.com/ee/development/service_ping/metrics_instrumentation.html

module Gitlab
  class UsageData
    MAX_GENERATION_TIME_FOR_SAAS = 40.hours

    CE_MEMOIZED_VALUES = %i[
      issue_minimum_id
      issue_maximum_id
      project_minimum_id
      project_maximum_id
      user_minimum_id
      user_maximum_id
      deployment_minimum_id
      deployment_maximum_id
      auth_providers
      recorded_at
    ].freeze

    class << self
      include Gitlab::Utils::UsageData
      include Gitlab::Utils::StrongMemoize
      include Gitlab::Usage::TimeFrame

      def data
        clear_memoized

        with_finished_at(:recording_ce_finished_at) do
          { recorded_at: recorded_at }
            .merge(usage_data_metrics)
        end
      end

      def recorded_at
        @recorded_at ||= Time.current
      end

      # rubocop: disable Metrics/AbcSize
      # rubocop: disable CodeReuse/ActiveRecord
      def system_usage_data
        {
          counts: {
            assignee_lists: count(List.assignee),
            ci_external_pipelines: count(::Ci::Pipeline.external),
            ci_pipeline_config_auto_devops: count(::Ci::Pipeline.auto_devops_source),
            ci_pipeline_config_repository: count(::Ci::Pipeline.repository_source),
            ci_triggers: count(::Ci::Trigger),
            ci_pipeline_schedules: count(::Ci::PipelineSchedule),
            auto_devops_enabled: count(::ProjectAutoDevops.enabled),
            auto_devops_disabled: count(::ProjectAutoDevops.disabled),
            deploy_keys: count(DeployKey),
            feature_flags: count(Operations::FeatureFlag),
            environments: count(::Environment),
            clusters: count(::Clusters::Cluster),
            clusters_enabled: count(::Clusters::Cluster.enabled),
            project_clusters_enabled: count(::Clusters::Cluster.enabled.project_type),
            group_clusters_enabled: count(::Clusters::Cluster.enabled.group_type),
            instance_clusters_enabled: count(::Clusters::Cluster.enabled.instance_type),
            clusters_disabled: count(::Clusters::Cluster.disabled),
            project_clusters_disabled: count(::Clusters::Cluster.disabled.project_type),
            group_clusters_disabled: count(::Clusters::Cluster.disabled.group_type),
            instance_clusters_disabled: count(::Clusters::Cluster.disabled.instance_type),
            clusters_platforms_eks: count(::Clusters::Cluster.aws_installed.enabled),
            clusters_platforms_gke: count(::Clusters::Cluster.gcp_installed.enabled),
            clusters_platforms_user: count(::Clusters::Cluster.user_provided.enabled),
            clusters_management_project: count(::Clusters::Cluster.with_management_project),
            clusters_integrations_prometheus: count(::Clusters::Integrations::Prometheus.enabled),
            kubernetes_agents: count(::Clusters::Agent),
            kubernetes_agents_with_token: distinct_count(::Clusters::AgentToken, :agent_id),
            in_review_folder: count(::Environment.in_review_folder),
            groups: count(Group),
            issues: add_metric('CountIssuesMetric', time_frame: 'all'),
            issues_created_from_gitlab_error_tracking_ui: count(SentryIssue),
            issues_with_associated_zoom_link: count(ZoomMeeting.added_to_issue),
            issues_using_zoom_quick_actions: distinct_count(ZoomMeeting, :issue_id),
            incident_issues: count(::Issue.with_issue_type(:incident), start: minimum_id(Issue), finish: maximum_id(Issue)),
            alert_bot_incident_issues: count(::Issue.authored(::Users::Internal.alert_bot), start: minimum_id(Issue), finish: maximum_id(Issue)),
            keys: count(Key),
            label_lists: count(List.label),
            lfs_objects: count(LfsObject),
            milestone_lists: count(List.milestone),
            milestones: count(Milestone),
            projects_with_packages: distinct_count(::Packages::Package, :project_id),
            packages: count(::Packages::Package),
            pages_domains: count(PagesDomain),
            pool_repositories: count(PoolRepository),
            projects: count(Project),
            projects_creating_incidents: distinct_count(Issue.with_issue_type(:incident), :project_id),
            projects_imported_from_github: count(Project.where(import_type: 'github')),
            projects_with_repositories_enabled: count(ProjectFeature.where('repository_access_level > ?', ProjectFeature::DISABLED)),
            projects_with_error_tracking_enabled: count(::ErrorTracking::ProjectErrorTrackingSetting.where(enabled: true)),
            projects_with_enabled_alert_integrations: distinct_count(::AlertManagement::HttpIntegration.active, :project_id),
            projects_with_terraform_reports: distinct_count(::Ci::JobArtifact.of_report_type(:terraform), :project_id),
            projects_with_terraform_states: distinct_count(::Terraform::State, :project_id),
            protected_branches: count(ProtectedBranch),
            protected_branches_except_default: count(ProtectedBranch.where.not(name: ['main', 'master', Gitlab::CurrentSettings.default_branch_name])),
            releases: count(Release),
            remote_mirrors: count(RemoteMirror),
            suggestions: count(Suggestion),
            terraform_reports: count(::Ci::JobArtifact.of_report_type(:terraform)),
            terraform_states: count(::Terraform::State),
            todos: count(Todo),
            uploads: count(Upload),
            web_hooks: count(WebHook),
            labels: count(Label),
            merge_requests: count(MergeRequest),
            notes: count(Note)
          }.merge(
            integrations_usage,
            user_preferences_usage,
            service_desk_counts
          )
        }
      end
      # rubocop: enable Metrics/AbcSize
      # rubocop: enable CodeReuse/ActiveRecord

      def system_usage_data_license
        {
          license: {}
        }
      end

      def system_usage_data_weekly
        {
          counts_weekly: {}
        }
      end

      def features_usage_data = {}

      def components_usage_data
        {
          git: { version: alt_usage_data(fallback: { major: -1 }) { Gitlab::Git.version } },
          gitaly: {
            version: alt_usage_data { Gitaly::Server.all.first.server_version },
            servers: alt_usage_data { Gitaly::Server.count },
            clusters: alt_usage_data { Gitaly::Server.gitaly_clusters },
            filesystems: alt_usage_data(fallback: ["-1"]) { Gitaly::Server.filesystems }
          },
          gitlab_pages: {
            enabled: alt_usage_data(fallback: nil) { Gitlab.config.pages.enabled },
            version: alt_usage_data { Gitlab::Pages::VERSION }
          },
          container_registry_server: {
            vendor: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.container_registry_vendor },
            version: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.container_registry_version }
          },
          database: {
            # rubocop: disable UsageData/LargeTable
            adapter: alt_usage_data { ApplicationRecord.database.adapter_name },
            version: alt_usage_data { ApplicationRecord.database.version },
            pg_system_id: alt_usage_data { ApplicationRecord.database.system_id },
            flavor: alt_usage_data { ApplicationRecord.database.flavor }
            # rubocop: enable UsageData/LargeTable
          },
          mail: {
            smtp_server: alt_usage_data { ActionMailer::Base.smtp_settings[:address] }
          }
        }
      end

      def object_store_config(component)
        config = alt_usage_data(fallback: nil) do
          Settings[component]['object_store']
        end

        if config.present?
          {
            enabled: alt_usage_data { Settings[component]['enabled'] },
            object_store: {
              enabled: alt_usage_data { config['enabled'] },
              direct_upload: alt_usage_data { config['direct_upload'] },
              background_upload: alt_usage_data { false }, # This setting no longer exists
              provider: alt_usage_data { config['connection']['provider'] }
            }
          }
        else
          {
            enabled: alt_usage_data { Settings[component]['enabled'] }
          }
        end
      end

      def object_store_usage_data
        {
          object_store: {
            artifacts: object_store_config('artifacts'),
            external_diffs: object_store_config('external_diffs'),
            lfs: object_store_config('lfs'),
            uploads: object_store_config('uploads'),
            packages: object_store_config('packages')
          }
        }
      end

      def topology_usage_data
        Gitlab::UsageData::Topology.new.topology_usage_data
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def integrations_usage
        # rubocop: disable UsageData/LargeTable:
        available_integrations.each_with_object({}) do |name, response|
          type = Integration.integration_name_to_type(name)

          response[:"projects_#{name}_active"] = count(Integration.active.where.not(project: nil).where(type: type))
          response[:"groups_#{name}_active"] = count(Integration.active.where.not(group: nil).where(type: type))
          response[:"instances_#{name}_active"] = count(Integration.active.where(instance: true, type: type))
          response[:"projects_inheriting_#{name}_active"] = count(Integration.active.where.not(project: nil).where.not(inherit_from_id: nil).where(type: type))
          response[:"groups_inheriting_#{name}_active"] = count(Integration.active.where.not(group: nil).where.not(inherit_from_id: nil).where(type: type))
        end.merge(jira_import_usage)
        # rubocop: enable UsageData/LargeTable:
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def jira_import_usage
        # rubocop: disable UsageData/LargeTable
        finished_jira_imports = JiraImportState.finished

        {
          jira_imports_total_imported_count: count(finished_jira_imports),
          jira_imports_projects_count: distinct_count(finished_jira_imports, :project_id),
          jira_imports_total_imported_issues_count: add_metric('JiraImportsTotalImportedIssuesCountMetric')
        }
        # rubocop: enable UsageData/LargeTable
      end

      # rubocop: disable CodeReuse/ActiveRecord
      # rubocop: disable UsageData/LargeTable
      def successful_deployments_with_cluster(scope)
        scope
          .joins(cluster: :deployments)
          .merge(::Clusters::Cluster.enabled)
          .merge(Deployment.success)
      end
      # rubocop: enable UsageData/LargeTable
      # rubocop: enable CodeReuse/ActiveRecord

      # augmented in EE
      def user_preferences_usage
        {
          user_preferences_user_gitpod_enabled: count(UserPreference.with_user.gitpod_enabled.merge(User.active))
        }
      end

      # Source: https://gitlab.com/gitlab-data/analytics/blob/master/transform/snowflake-dbt/data/ping_metrics_to_stage_mapping_data.csv
      def usage_activity_by_stage(key = :usage_activity_by_stage, time_period = {})
        {
          key => {
            configure: usage_activity_by_stage_configure(time_period),
            create: usage_activity_by_stage_create(time_period),
            enablement: usage_activity_by_stage_enablement(time_period),
            manage: usage_activity_by_stage_manage(time_period),
            monitor: usage_activity_by_stage_monitor(time_period),
            package: usage_activity_by_stage_package(time_period),
            plan: usage_activity_by_stage_plan(time_period),
            release: usage_activity_by_stage_release(time_period),
            verify: usage_activity_by_stage_verify(time_period)
          }
        }
      end

      # rubocop: disable CodeReuse/ActiveRecord
      # rubocop: disable UsageData/LargeTable
      def usage_activity_by_stage_configure(time_period)
        {
          clusters_management_project: clusters_user_distinct_count(::Clusters::Cluster.with_management_project, time_period),
          clusters_disabled: clusters_user_distinct_count(::Clusters::Cluster.disabled, time_period),
          clusters_enabled: clusters_user_distinct_count(::Clusters::Cluster.enabled, time_period),
          clusters_platforms_gke: clusters_user_distinct_count(::Clusters::Cluster.gcp_installed.enabled, time_period),
          clusters_platforms_eks: clusters_user_distinct_count(::Clusters::Cluster.aws_installed.enabled, time_period),
          clusters_platforms_user: clusters_user_distinct_count(::Clusters::Cluster.user_provided.enabled, time_period),
          instance_clusters_disabled: clusters_user_distinct_count(::Clusters::Cluster.disabled.instance_type, time_period),
          instance_clusters_enabled: clusters_user_distinct_count(::Clusters::Cluster.enabled.instance_type, time_period),
          group_clusters_disabled: clusters_user_distinct_count(::Clusters::Cluster.disabled.group_type, time_period),
          group_clusters_enabled: clusters_user_distinct_count(::Clusters::Cluster.enabled.group_type, time_period),
          project_clusters_disabled: clusters_user_distinct_count(::Clusters::Cluster.disabled.project_type, time_period),
          project_clusters_enabled: clusters_user_distinct_count(::Clusters::Cluster.enabled.project_type, time_period),
          # These two `projects_slack_x` metrics are owned by the Manage stage, but are in this method as their key paths can't change.
          # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123442#note_1427961339.
          projects_slack_notifications_active: distinct_count(::Project.with_slack_integration.where(time_period), :creator_id),
          projects_slack_slash_active: distinct_count(::Project.with_slack_slash_commands_integration.where(time_period), :creator_id)
        }
      end
      # rubocop: enable UsageData/LargeTable
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_create(time_period)
        {
          deploy_keys: distinct_count(::DeployKey.where(time_period), :user_id),
          keys: distinct_count(::Key.regular_keys.where(time_period), :user_id),
          projects_with_disable_overriding_approvers_per_merge_request: count(::Project.where(time_period.merge(disable_overriding_approvers_per_merge_request: true))),
          projects_without_disable_overriding_approvers_per_merge_request: count(::Project.where(time_period.merge(disable_overriding_approvers_per_merge_request: [false, nil]))),
          remote_mirrors: distinct_count(::Project.with_remote_mirrors.where(time_period), :creator_id),
          snippets: distinct_count(::Snippet.where(time_period), :author_id)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Empty placeholder allows this to match the pattern used by other sections
      def usage_activity_by_stage_enablement(time_period)
        {}
      end

      # Omitted because no user, creator or author associated: `campaigns_imported_from_github`, `ldap_group_links`
      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_manage(time_period)
        {
          # rubocop: disable UsageData/LargeTable
          events: stage_manage_events(time_period),
          groups: distinct_count(::GroupMember.where(time_period), :user_id),
          users_created: count(::User.where(time_period), start: minimum_id(User), finish: maximum_id(User)),
          omniauth_providers: filtered_omniauth_provider_names.reject { |name| name == 'group_saml' },
          user_auth_by_provider: distinct_count_user_auth_by_provider(time_period),
          bulk_imports: {
            gitlab_v1: count(::BulkImport.where(**time_period, source_type: :gitlab))
          },
          group_imports: group_imports(time_period)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_monitor(time_period)
        # Calculate histogram only for overall as other time periods aren't available/useful here.
        integrations_histogram = time_period.empty? ? histogram(::AlertManagement::HttpIntegration.active, :project_id, buckets: 1..100) : nil

        {
          clusters: distinct_count(::Clusters::Cluster.where(time_period), :user_id),
          clusters_integrations_prometheus: cluster_integrations_user_distinct_count(::Clusters::Integrations::Prometheus, time_period),
          operations_dashboard_default_dashboard: count(::User.active.with_dashboard('operations').where(time_period),
            start: minimum_id(User),
            finish: maximum_id(User)),
          projects_with_error_tracking_enabled: distinct_count(::Project.with_enabled_error_tracking.where(time_period), :creator_id),
          projects_with_incidents: distinct_count(::Issue.with_issue_type(:incident).where(time_period), :project_id),
          # We are making an assumption here that all alert_management_alerts are associated with an issue of type
          # incident. In reality this is very close to the truth and allows more efficient queries.
          # More info in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121297#note_1416999956
          projects_with_alert_incidents: distinct_count(::AlertManagement::Alert.where(time_period).where.not(issue_id: nil), :project_id),
          projects_with_enabled_alert_integrations_histogram: integrations_histogram
        }.compact
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_package(time_period)
        {
          projects_with_packages: distinct_count(::Project.with_packages.where(time_period), :creator_id)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Omitted because no user, creator or author associated: `boards`, `labels`, `milestones`, `uploads`
      # Omitted because too expensive: `epics_deepest_relationship_level`
      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_plan(time_period)
        time_frame = metric_time_period(time_period)
        {
          issues: add_metric('CountUsersCreatingIssuesMetric', time_frame: time_frame),
          notes: distinct_count(::Note.where(time_period), :author_id),
          projects: distinct_count(::Project.where(time_period), :creator_id),
          todos: distinct_count(::Todo.where(time_period), :author_id),
          service_desk_enabled_projects: distinct_count_service_desk_enabled_projects(time_period),
          service_desk_issues: count(::Issue.service_desk.where(time_period)),
          projects_jira_active: distinct_count(::Project.with_active_integration(::Integrations::Jira).where(time_period), :creator_id),
          projects_jira_dvcs_server_active: distinct_count(::Project.with_active_integration(::Integrations::Jira).with_jira_dvcs_server.where(time_period), :creator_id)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Omitted because no user, creator or author associated: `environments`, `feature_flags`, `in_review_folder`, `pages_domains`
      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_release(time_period)
        time_frame = metric_time_period(time_period)
        {
          deployments: distinct_count(::Deployment.where(time_period), :user_id),
          failed_deployments: distinct_count(::Deployment.failed.where(time_period), :user_id),
          releases: distinct_count(::Release.where(time_period), :author_id),
          successful_deployments: distinct_count(::Deployment.success.where(time_period), :user_id),
          releases_with_milestones: add_metric('CountUsersAssociatingMilestonesToReleasesMetric', time_frame: time_frame)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Omitted because no user, creator or author associated: `ci_runners`
      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_verify(time_period)
        {
          ci_builds: distinct_count(::Ci::Build.where(time_period), :user_id),
          ci_external_pipelines: distinct_count(::Ci::Pipeline.external.where(time_period), :user_id, start: minimum_id(User), finish: maximum_id(User)),
          ci_internal_pipelines: distinct_count(::Ci::Pipeline.internal.where(time_period), :user_id, start: minimum_id(User), finish: maximum_id(User)),
          ci_pipeline_config_auto_devops: distinct_count(::Ci::Pipeline.auto_devops_source.where(time_period), :user_id, start: minimum_id(User), finish: maximum_id(User)),
          ci_pipeline_config_repository: distinct_count(::Ci::Pipeline.repository_source.where(time_period), :user_id, start: minimum_id(User), finish: maximum_id(User)),
          ci_pipeline_schedules: distinct_count(::Ci::PipelineSchedule.where(time_period), :owner_id),
          ci_pipelines: distinct_count(::Ci::Pipeline.where(time_period), :user_id, start: minimum_id(User), finish: maximum_id(User)),
          ci_triggers: distinct_count(::Ci::Trigger.where(time_period), :owner_id)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def with_metadata
        result = nil
        error = nil

        duration = Benchmark.realtime do
          result = yield
        rescue StandardError => e
          error = e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error)
        end

        ::Gitlab::Usage::ServicePing::LegacyMetricMetadataDecorator.new(result, duration, error: error)
      end

      private

      def stage_manage_events(time_period)
        if time_period.empty?
          Gitlab::Utils::UsageData::FALLBACK
        else
          # rubocop: disable CodeReuse/ActiveRecord
          start = ::Event.where(time_period).select(:id).order(created_at: :asc).first&.id
          finish = ::Event.where(time_period).select(:id).order(created_at: :desc).first&.id
          estimate_batch_distinct_count(::Event.where(time_period), :author_id, start: start, finish: finish)
          # rubocop: enable UsageData/LargeTable
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end

      def usage_data_metrics
        system_usage_data_license
          .merge(system_usage_data)
          .merge(system_usage_data_weekly)
          .merge(features_usage_data)
          .merge(components_usage_data)
          .merge(object_store_usage_data)
          .merge(topology_usage_data)
          .merge(usage_activity_by_stage)
          .merge(usage_activity_by_stage(:usage_activity_by_stage_monthly, monthly_time_range_db_params))
      end

      def metric_time_period(time_period)
        time_period.present? ? '28d' : 'none'
      end

      def distinct_count_service_desk_enabled_projects(time_period)
        project_creator_id_start = minimum_id(User)
        project_creator_id_finish = maximum_id(User)

        distinct_count(::Project.service_desk_enabled.where(time_period), :creator_id, start: project_creator_id_start, finish: project_creator_id_finish) # rubocop: disable CodeReuse/ActiveRecord
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def service_desk_counts
        # rubocop: disable UsageData/LargeTable:
        projects_with_service_desk = ::Project.where(service_desk_enabled: true)
        # rubocop: enable UsageData/LargeTable:
        {
          service_desk_enabled_projects: count(projects_with_service_desk),
          service_desk_issues: count(
            ::Issue.where(
              project: projects_with_service_desk,
              author: ::Users::Internal.support_bot,
              confidential: true
            )
          )
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def clear_memoized
        CE_MEMOIZED_VALUES.each { |v| clear_memoization(v) }
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def cluster_integrations_user_distinct_count(integrations, time_period)
        distinct_count(integrations.where(time_period).enabled.joins(:cluster), 'clusters.user_id')
      end

      def clusters_user_distinct_count(clusters, time_period)
        distinct_count(clusters.where(time_period), :user_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def omniauth_provider_names
        ::Gitlab.config.omniauth.providers.map(&:name)
      end

      # Overridden in EE
      def available_integrations
        Integration.available_integration_names(include_dev: false, include_disabled: true) # rubocop: disable UsageData/LargeTable -- not counting data
      end

      # LDAP provider names are set by customers and could include
      # sensitive info (server names, etc). LDAP providers normally
      # don't appear in omniauth providers but filter to ensure
      # no internal details leak via usage ping.
      def filtered_omniauth_provider_names
        omniauth_provider_names.reject { |name| name.starts_with?('ldap') }
      end

      def group_imports(time_period)
        time_frame = metric_time_period(time_period)
        {
          group_import: count(::GroupImportState.where(time_period)), # rubocop: disable CodeReuse/ActiveRecord
          gitlab_migration: add_metric('CountBulkImportsEntitiesMetric', time_frame: time_frame, options: { source_type: :group_entity })
        }
      end

      # rubocop:disable CodeReuse/ActiveRecord
      def distinct_count_user_auth_by_provider(time_period)
        counts = auth_providers_except_ldap.index_with do |provider|
          distinct_count(
            ::AuthenticationEvent.success.for_provider(provider).where(time_period), :user_id)
        end

        if any_ldap_auth_providers?
          counts['ldap'] = distinct_count(
            ::AuthenticationEvent.success.ldap.where(time_period), :user_id
          )
        end

        counts
      end
      # rubocop:enable CodeReuse/ActiveRecord

      # rubocop:disable UsageData/LargeTable
      def auth_providers
        strong_memoize(:auth_providers) do
          ::AuthenticationEvent.providers
        end
      end
      # rubocop:enable UsageData/LargeTable

      def auth_providers_except_ldap
        auth_providers.reject { |provider| provider.starts_with?('ldap') }
      end

      def any_ldap_auth_providers?
        auth_providers.any? { |provider| provider.starts_with?('ldap') }
      end
    end
  end
end

Gitlab::UsageData.prepend_mod_with('Gitlab::UsageData')
