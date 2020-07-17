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
#   redis_usage_data { ::Gitlab::UsageCounters::PodLogs.usage_totals[:total] }

module Gitlab
  class UsageData
    BATCH_SIZE = 100

    class << self
      include Gitlab::Utils::UsageData
      include Gitlab::Utils::StrongMemoize

      def data(force_refresh: false)
        Rails.cache.fetch('usage_data', force: force_refresh, expires_in: 2.weeks) do
          uncached_data
        end
      end

      def uncached_data
        clear_memoized

        with_finished_at(:recording_ce_finished_at) do
          license_usage_data
            .merge(system_usage_data)
            .merge(system_usage_data_monthly)
            .merge(features_usage_data)
            .merge(components_usage_data)
            .merge(cycle_analytics_usage_data)
            .merge(object_store_usage_data)
            .merge(topology_usage_data)
            .merge(usage_activity_by_stage)
            .merge(usage_activity_by_stage(:usage_activity_by_stage_monthly, last_28_days_time_period))
            .merge(analytics_unique_visits_data)
        end
      end

      def to_json(force_refresh: false)
        data(force_refresh: force_refresh).to_json
      end

      def license_usage_data
        {
          recorded_at: recorded_at,
          uuid: alt_usage_data { Gitlab::CurrentSettings.uuid },
          hostname: alt_usage_data { Gitlab.config.gitlab.host },
          version: alt_usage_data { Gitlab::VERSION },
          installation_type: alt_usage_data { installation_type },
          active_user_count: count(User.active),
          edition: 'CE'
        }
      end

      def recorded_at
        Time.now
      end

      # rubocop: disable Metrics/AbcSize
      # rubocop: disable CodeReuse/ActiveRecord
      def system_usage_data
        alert_bot_incident_count = count(::Issue.authored(::User.alert_bot), start: issue_minimum_id, finish: issue_maximum_id)
        issues_created_manually_from_alerts = count(Issue.with_alert_management_alerts.not_authored_by(::User.alert_bot), start: issue_minimum_id, finish: issue_maximum_id)

        {
          counts: {
            assignee_lists: count(List.assignee),
            boards: count(Board),
            ci_builds: count(::Ci::Build),
            ci_internal_pipelines: count(::Ci::Pipeline.internal),
            ci_external_pipelines: count(::Ci::Pipeline.external),
            ci_pipeline_config_auto_devops: count(::Ci::Pipeline.auto_devops_source),
            ci_pipeline_config_repository: count(::Ci::Pipeline.repository_source),
            ci_runners: count(::Ci::Runner),
            ci_triggers: count(::Ci::Trigger),
            ci_pipeline_schedules: count(::Ci::PipelineSchedule),
            auto_devops_enabled: count(::ProjectAutoDevops.enabled),
            auto_devops_disabled: count(::ProjectAutoDevops.disabled),
            deploy_keys: count(DeployKey),
            deployments: deployment_count(Deployment),
            successful_deployments: deployment_count(Deployment.success),
            failed_deployments: deployment_count(Deployment.failed),
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
            clusters_applications_helm: count(::Clusters::Applications::Helm.available),
            clusters_applications_ingress: count(::Clusters::Applications::Ingress.available),
            clusters_applications_cert_managers: count(::Clusters::Applications::CertManager.available),
            clusters_applications_crossplane: count(::Clusters::Applications::Crossplane.available),
            clusters_applications_prometheus: count(::Clusters::Applications::Prometheus.available),
            clusters_applications_runner: count(::Clusters::Applications::Runner.available),
            clusters_applications_knative: count(::Clusters::Applications::Knative.available),
            clusters_applications_elastic_stack: count(::Clusters::Applications::ElasticStack.available),
            clusters_applications_jupyter: count(::Clusters::Applications::Jupyter.available),
            clusters_applications_cilium: count(::Clusters::Applications::Cilium.available),
            clusters_management_project: count(::Clusters::Cluster.with_management_project),
            in_review_folder: count(::Environment.in_review_folder),
            grafana_integrated_projects: count(GrafanaIntegration.enabled),
            groups: count(Group),
            issues: count(Issue, start: issue_minimum_id, finish: issue_maximum_id),
            issues_created_from_gitlab_error_tracking_ui: count(SentryIssue),
            issues_with_associated_zoom_link: count(ZoomMeeting.added_to_issue),
            issues_using_zoom_quick_actions: distinct_count(ZoomMeeting, :issue_id),
            issues_with_embedded_grafana_charts_approx: grafana_embed_usage_data,
            issues_created_from_alerts: total_alert_issues,
            issues_created_gitlab_alerts: issues_created_manually_from_alerts,
            issues_created_manually_from_alerts: issues_created_manually_from_alerts,
            incident_issues: alert_bot_incident_count,
            alert_bot_incident_issues: alert_bot_incident_count,
            incident_labeled_issues: count(::Issue.with_label_attributes(::IncidentManagement::CreateIncidentLabelService::LABEL_PROPERTIES), start: issue_minimum_id, finish: issue_maximum_id),
            keys: count(Key),
            label_lists: count(List.label),
            lfs_objects: count(LfsObject),
            milestone_lists: count(List.milestone),
            milestones: count(Milestone),
            pages_domains: count(PagesDomain),
            pool_repositories: count(PoolRepository),
            projects: count(Project),
            projects_imported_from_github: count(Project.where(import_type: 'github')),
            projects_with_repositories_enabled: count(ProjectFeature.where('repository_access_level > ?', ProjectFeature::DISABLED)),
            projects_with_error_tracking_enabled: count(::ErrorTracking::ProjectErrorTrackingSetting.where(enabled: true)),
            projects_with_alerts_service_enabled: count(AlertsService.active),
            projects_with_prometheus_alerts: distinct_count(PrometheusAlert, :project_id),
            projects_with_terraform_reports: distinct_count(::Ci::JobArtifact.terraform_reports, :project_id),
            projects_with_terraform_states: distinct_count(::Terraform::State, :project_id),
            protected_branches: count(ProtectedBranch),
            releases: count(Release),
            remote_mirrors: count(RemoteMirror),
            personal_snippets: count(PersonalSnippet),
            project_snippets: count(ProjectSnippet),
            suggestions: count(Suggestion),
            terraform_reports: count(::Ci::JobArtifact.terraform_reports),
            terraform_states: count(::Terraform::State),
            todos: count(Todo),
            uploads: count(Upload),
            web_hooks: count(WebHook),
            labels: count(Label),
            merge_requests: count(MergeRequest),
            notes: count(Note)
          }.merge(
            services_usage,
            usage_counters,
            user_preferences_usage,
            ingress_modsecurity_usage,
            container_expiration_policies_usage
          ).tap do |data|
            data[:snippets] = data[:personal_snippets] + data[:project_snippets]
          end
        }
      end
      # rubocop: enable Metrics/AbcSize

      def system_usage_data_monthly
        {
          counts_monthly: {
            deployments: deployment_count(Deployment.where(last_28_days_time_period)),
            successful_deployments: deployment_count(Deployment.success.where(last_28_days_time_period)),
            failed_deployments: deployment_count(Deployment.failed.where(last_28_days_time_period)),
            personal_snippets: count(PersonalSnippet.where(last_28_days_time_period)),
            project_snippets: count(ProjectSnippet.where(last_28_days_time_period))
          }.tap do |data|
            data[:snippets] = data[:personal_snippets] + data[:project_snippets]
          end
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def cycle_analytics_usage_data
        Gitlab::CycleAnalytics::UsageData.new.to_json
      rescue ActiveRecord::StatementInvalid
        { avg_cycle_analytics: {} }
      end

      # rubocop:disable CodeReuse/ActiveRecord
      def grafana_embed_usage_data
        count(Issue.joins('JOIN grafana_integrations USING (project_id)')
          .where("issues.description LIKE '%' || grafana_integrations.grafana_url || '%'")
          .where(grafana_integrations: { enabled: true }))
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def features_usage_data
        features_usage_data_ce
      end

      def features_usage_data_ce
        {
          instance_auto_devops_enabled: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.auto_devops_enabled? },
          container_registry_enabled: alt_usage_data(fallback: nil) { Gitlab.config.registry.enabled },
          dependency_proxy_enabled: Gitlab.config.try(:dependency_proxy)&.enabled,
          gitlab_shared_runners_enabled: alt_usage_data(fallback: nil) { Gitlab.config.gitlab_ci.shared_runners_enabled },
          gravatar_enabled: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.gravatar_enabled? },
          ldap_enabled: alt_usage_data(fallback: nil) { Gitlab.config.ldap.enabled },
          mattermost_enabled: alt_usage_data(fallback: nil) { Gitlab.config.mattermost.enabled },
          omniauth_enabled: alt_usage_data(fallback: nil) { Gitlab::Auth.omniauth_enabled? },
          prometheus_enabled: alt_usage_data(fallback: nil) { Gitlab::Prometheus::Internal.prometheus_enabled? },
          prometheus_metrics_enabled: alt_usage_data(fallback: nil) { Gitlab::Metrics.prometheus_metrics_enabled? },
          reply_by_email_enabled: alt_usage_data(fallback: nil) { Gitlab::IncomingEmail.enabled? },
          signup_enabled: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.allow_signup? },
          web_ide_clientside_preview_enabled: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.web_ide_clientside_preview_enabled? },
          ingress_modsecurity_enabled: Feature.enabled?(:ingress_modsecurity),
          grafana_link_enabled: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.grafana_enabled? }
        }
      end

      # @return [Hash<Symbol, Integer>]
      def usage_counters
        usage_data_counters.map { |counter| redis_usage_data(counter) }.reduce({}, :merge)
      end

      # @return [Array<#totals>] An array of objects that respond to `#totals`
      def usage_data_counters
        [
          Gitlab::UsageDataCounters::WikiPageCounter,
          Gitlab::UsageDataCounters::WebIdeCounter,
          Gitlab::UsageDataCounters::NoteCounter,
          Gitlab::UsageDataCounters::SnippetCounter,
          Gitlab::UsageDataCounters::SearchCounter,
          Gitlab::UsageDataCounters::CycleAnalyticsCounter,
          Gitlab::UsageDataCounters::ProductivityAnalyticsCounter,
          Gitlab::UsageDataCounters::SourceCodeCounter,
          Gitlab::UsageDataCounters::MergeRequestCounter,
          Gitlab::UsageDataCounters::DesignsCounter
        ]
      end

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
          container_registry: {
            vendor: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.container_registry_vendor },
            version: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.container_registry_version }
          },
          database: {
            adapter: alt_usage_data { Gitlab::Database.adapter_name },
            version: alt_usage_data { Gitlab::Database.version }
          },
          app_server: { type: app_server_type }
        }
      end

      def app_server_type
        Gitlab::Runtime.identify.to_s
      rescue Gitlab::Runtime::IdentificationError => e
        Gitlab::AppLogger.error(e.message)
        Gitlab::ErrorTracking.track_exception(e)
        'unknown_app_server_type'
      end

      def object_store_config(component)
        config = alt_usage_data(fallback: nil) do
          Settings[component]['object_store']
        end

        if config
          {
            enabled: alt_usage_data { Settings[component]['enabled'] },
            object_store: {
              enabled: alt_usage_data { config['enabled'] },
              direct_upload: alt_usage_data { config['direct_upload'] },
              background_upload: alt_usage_data { config['background_upload'] },
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

      def ingress_modsecurity_usage
        ##
        # This method measures usage of the Modsecurity Web Application Firewall across the entire
        # instance's deployed environments.
        #
        # NOTE: this service is an approximation as it does not yet take into account if environment
        # is enabled and only measures applications installed using GitLab Managed Apps (disregards
        # CI-based managed apps).
        #
        # More details: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28331#note_318621786
        ##

        column = ::Deployment.arel_table[:environment_id]
        {
          ingress_modsecurity_logging: distinct_count(successful_deployments_with_cluster(::Clusters::Applications::Ingress.modsecurity_enabled.logging), column),
          ingress_modsecurity_blocking: distinct_count(successful_deployments_with_cluster(::Clusters::Applications::Ingress.modsecurity_enabled.blocking), column),
          ingress_modsecurity_disabled: distinct_count(successful_deployments_with_cluster(::Clusters::Applications::Ingress.modsecurity_disabled), column),
          ingress_modsecurity_not_installed: distinct_count(successful_deployments_with_cluster(::Clusters::Applications::Ingress.modsecurity_not_installed), column)
        }
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def container_expiration_policies_usage
        results = {}
        start = ::Project.minimum(:id)
        finish = ::Project.maximum(:id)

        results[:projects_with_expiration_policy_disabled] = distinct_count(::ContainerExpirationPolicy.where(enabled: false), :project_id, start: start, finish: finish)
        base = ::ContainerExpirationPolicy.active
        results[:projects_with_expiration_policy_enabled] = distinct_count(base, :project_id, start: start, finish: finish)

        %i[keep_n cadence older_than].each do |option|
          ::ContainerExpirationPolicy.public_send("#{option}_options").keys.each do |value| # rubocop: disable GitlabSecurity/PublicSend
            results["projects_with_expiration_policy_enabled_with_#{option}_set_to_#{value}".to_sym] = distinct_count(base.where(option => value), :project_id, start: start, finish: finish)
          end
        end

        results[:projects_with_expiration_policy_enabled_with_keep_n_unset] = distinct_count(base.where(keep_n: nil), :project_id, start: start, finish: finish)
        results[:projects_with_expiration_policy_enabled_with_older_than_unset] = distinct_count(base.where(older_than: nil), :project_id, start: start, finish: finish)

        results
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def services_usage
        Service.available_services_names.without('jira').each_with_object({}) do |service_name, response|
          response["projects_#{service_name}_active".to_sym] = count(Service.active.where(template: false, type: "#{service_name}_service".camelize))
        end.merge(jira_usage).merge(jira_import_usage)
      end

      def jira_usage
        # Jira Cloud does not support custom domains as per https://jira.atlassian.com/browse/CLOUD-6999
        # so we can just check for subdomains of atlassian.net

        results = {
          projects_jira_server_active: 0,
          projects_jira_cloud_active: 0,
          projects_jira_active: 0
        }

        JiraService.active.includes(:jira_tracker_data).find_in_batches(batch_size: BATCH_SIZE) do |services|
          counts = services.group_by do |service|
            # TODO: Simplify as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
            service_url = service.data_fields&.url || (service.properties && service.properties['url'])
            service_url&.include?('.atlassian.net') ? :cloud : :server
          end

          results[:projects_jira_server_active] += counts[:server].size if counts[:server]
          results[:projects_jira_cloud_active] += counts[:cloud].size if counts[:cloud]
          results[:projects_jira_active] += services.size
        end

        results
      rescue ActiveRecord::StatementInvalid
        { projects_jira_server_active: FALLBACK, projects_jira_cloud_active: FALLBACK, projects_jira_active: FALLBACK }
      end

      def successful_deployments_with_cluster(scope)
        scope
          .joins(cluster: :deployments)
          .merge(Clusters::Cluster.enabled)
          .merge(Deployment.success)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def jira_import_usage
        finished_jira_imports = JiraImportState.finished

        {
          jira_imports_total_imported_count: count(finished_jira_imports),
          jira_imports_projects_count: distinct_count(finished_jira_imports, :project_id),
          jira_imports_total_imported_issues_count: alt_usage_data { JiraImportState.finished_imports_count }
        }
      end

      def user_preferences_usage
        {} # augmented in EE
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def merge_requests_users(time_period)
        query =
          Event
            .where(target_type: Event::TARGET_TYPES[:merge_request].to_s)
            .where(time_period)

        distinct_count(
          query,
          :author_id,
          start: user_minimum_id,
          finish: user_maximum_id
        )
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def installation_type
        if Rails.env.production?
          Gitlab::INSTALLATION_TYPE
        else
          "gitlab-development-kit"
        end
      end

      def last_28_days_time_period
        { created_at: 28.days.ago..Time.current }
      end

      # Source: https://gitlab.com/gitlab-data/analytics/blob/master/transform/snowflake-dbt/data/ping_metrics_to_stage_mapping_data.csv
      def usage_activity_by_stage(key = :usage_activity_by_stage, time_period = {})
        {
          key => {
            configure: usage_activity_by_stage_configure(time_period),
            create: usage_activity_by_stage_create(time_period),
            manage: usage_activity_by_stage_manage(time_period),
            monitor: usage_activity_by_stage_monitor(time_period),
            package: usage_activity_by_stage_package(time_period),
            plan: usage_activity_by_stage_plan(time_period),
            release: usage_activity_by_stage_release(time_period),
            secure: usage_activity_by_stage_secure(time_period),
            verify: usage_activity_by_stage_verify(time_period)
          }
        }
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_configure(time_period)
        {
          clusters_applications_cert_managers: cluster_applications_user_distinct_count(::Clusters::Applications::CertManager, time_period),
          clusters_applications_helm: cluster_applications_user_distinct_count(::Clusters::Applications::Helm, time_period),
          clusters_applications_ingress: cluster_applications_user_distinct_count(::Clusters::Applications::Ingress, time_period),
          clusters_applications_knative: cluster_applications_user_distinct_count(::Clusters::Applications::Knative, time_period),
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
          project_clusters_enabled: clusters_user_distinct_count(::Clusters::Cluster.enabled.project_type, time_period)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_create(time_period)
        {
          deploy_keys: distinct_count(::DeployKey.where(time_period), :user_id),
          keys: distinct_count(::Key.regular_keys.where(time_period), :user_id),
          merge_requests: distinct_count(::MergeRequest.where(time_period), :author_id),
          projects_with_disable_overriding_approvers_per_merge_request: count(::Project.where(time_period.merge(disable_overriding_approvers_per_merge_request: true))),
          projects_without_disable_overriding_approvers_per_merge_request: count(::Project.where(time_period.merge(disable_overriding_approvers_per_merge_request: [false, nil]))),
          remote_mirrors: distinct_count(::Project.with_remote_mirrors.where(time_period), :creator_id),
          snippets: distinct_count(::Snippet.where(time_period), :author_id)
        }.tap do |h|
          if time_period.present?
            h[:merge_requests_users] = merge_requests_users(time_period)
            h.merge!(action_monthly_active_users(time_period))
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Omitted because no user, creator or author associated: `campaigns_imported_from_github`, `ldap_group_links`
      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_manage(time_period)
        {
          events: distinct_count(::Event.where(time_period), :author_id),
          groups: distinct_count(::GroupMember.where(time_period), :user_id),
          users_created: count(::User.where(time_period), start: user_minimum_id, finish: user_maximum_id),
          omniauth_providers: filtered_omniauth_provider_names.reject { |name| name == 'group_saml' }
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_monitor(time_period)
        {
          clusters: distinct_count(::Clusters::Cluster.where(time_period), :user_id),
          clusters_applications_prometheus: cluster_applications_user_distinct_count(::Clusters::Applications::Prometheus, time_period),
          operations_dashboard_default_dashboard: count(::User.active.with_dashboard('operations').where(time_period),
                                                        start: user_minimum_id,
                                                        finish: user_maximum_id)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def usage_activity_by_stage_package(time_period)
        {}
      end

      # Omitted because no user, creator or author associated: `boards`, `labels`, `milestones`, `uploads`
      # Omitted because too expensive: `epics_deepest_relationship_level`
      # Omitted because of encrypted properties: `projects_jira_cloud_active`, `projects_jira_server_active`
      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_plan(time_period)
        {
          issues: distinct_count(::Issue.where(time_period), :author_id),
          notes: distinct_count(::Note.where(time_period), :author_id),
          projects: distinct_count(::Project.where(time_period), :creator_id),
          todos: distinct_count(::Todo.where(time_period), :author_id)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Omitted because no user, creator or author associated: `environments`, `feature_flags`, `in_review_folder`, `pages_domains`
      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_release(time_period)
        {
          deployments: distinct_count(::Deployment.where(time_period), :user_id),
          failed_deployments: distinct_count(::Deployment.failed.where(time_period), :user_id),
          releases: distinct_count(::Release.where(time_period), :author_id),
          successful_deployments: distinct_count(::Deployment.success.where(time_period), :user_id)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Omitted because no user, creator or author associated: `ci_runners`
      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_verify(time_period)
        {
          ci_builds: distinct_count(::Ci::Build.where(time_period), :user_id),
          ci_external_pipelines: distinct_count(::Ci::Pipeline.external.where(time_period), :user_id, start: user_minimum_id, finish: user_maximum_id),
          ci_internal_pipelines: distinct_count(::Ci::Pipeline.internal.where(time_period), :user_id, start: user_minimum_id, finish: user_maximum_id),
          ci_pipeline_config_auto_devops: distinct_count(::Ci::Pipeline.auto_devops_source.where(time_period), :user_id, start: user_minimum_id, finish: user_maximum_id),
          ci_pipeline_config_repository: distinct_count(::Ci::Pipeline.repository_source.where(time_period), :user_id, start: user_minimum_id, finish: user_maximum_id),
          ci_pipeline_schedules: distinct_count(::Ci::PipelineSchedule.where(time_period), :owner_id),
          ci_pipelines: distinct_count(::Ci::Pipeline.where(time_period), :user_id, start: user_minimum_id, finish: user_maximum_id),
          ci_triggers: distinct_count(::Ci::Trigger.where(time_period), :owner_id),
          clusters_applications_runner: cluster_applications_user_distinct_count(::Clusters::Applications::Runner, time_period)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Currently too complicated and to get reliable counts for these stats:
      # container_scanning_jobs, dast_jobs, dependency_scanning_jobs, license_management_jobs, sast_jobs, secret_detection_jobs
      # Once https://gitlab.com/gitlab-org/gitlab/merge_requests/17568 is merged, this might be doable
      def usage_activity_by_stage_secure(time_period)
        {}
      end

      def analytics_unique_visits_data
        results = ::Gitlab::Analytics::UniqueVisits::TARGET_IDS.each_with_object({}) do |target_id, hash|
          hash[target_id] = redis_usage_data { unique_visit_service.weekly_unique_visits_for_target(target_id) }
        end
        results['analytics_unique_visits_for_any_target'] = redis_usage_data { unique_visit_service.weekly_unique_visits_for_any_target }

        { analytics_unique_visits: results }
      end

      def action_monthly_active_users(time_period)
        return {} unless Feature.enabled?(Gitlab::UsageDataCounters::TrackUniqueActions::FEATURE_FLAG)

        counter = Gitlab::UsageDataCounters::TrackUniqueActions

        project_count = redis_usage_data do
          counter.count_unique_events(
            event_action: Gitlab::UsageDataCounters::TrackUniqueActions::PUSH_ACTION,
            date_from: time_period[:created_at].first,
            date_to: time_period[:created_at].last
          )
        end

        design_count = redis_usage_data do
          counter.count_unique_events(
            event_action: Gitlab::UsageDataCounters::TrackUniqueActions::DESIGN_ACTION,
            date_from: time_period[:created_at].first,
            date_to: time_period[:created_at].last
          )
        end

        wiki_count = redis_usage_data do
          counter.count_unique_events(
            event_action: Gitlab::UsageDataCounters::TrackUniqueActions::WIKI_ACTION,
            date_from: time_period[:created_at].first,
            date_to: time_period[:created_at].last
          )
        end

        {
          action_monthly_active_users_project_repo: project_count,
          action_monthly_active_users_design_management: design_count,
          action_monthly_active_users_wiki_repo: wiki_count
        }
      end

      private

      def unique_visit_service
        strong_memoize(:unique_visit_service) do
          ::Gitlab::Analytics::UniqueVisits.new
        end
      end

      def total_alert_issues
        # Remove prometheus table queries once they are deprecated
        # To be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/217407.
        [
          count(Issue.with_alert_management_alerts, start: issue_minimum_id, finish: issue_maximum_id),
          count(::Issue.with_self_managed_prometheus_alert_events, start: issue_minimum_id, finish: issue_maximum_id),
          count(::Issue.with_prometheus_alert_events, start: issue_minimum_id, finish: issue_maximum_id)
        ].reduce(:+)
      end

      def user_minimum_id
        strong_memoize(:user_minimum_id) do
          ::User.minimum(:id)
        end
      end

      def user_maximum_id
        strong_memoize(:user_maximum_id) do
          ::User.maximum(:id)
        end
      end

      def issue_minimum_id
        strong_memoize(:issue_minimum_id) do
          ::Issue.minimum(:id)
        end
      end

      def issue_maximum_id
        strong_memoize(:issue_maximum_id) do
          ::Issue.maximum(:id)
        end
      end

      def deployment_minimum_id
        strong_memoize(:deployment_minimum_id) do
          ::Deployment.minimum(:id)
        end
      end

      def deployment_maximum_id
        strong_memoize(:deployment_maximum_id) do
          ::Deployment.maximum(:id)
        end
      end

      def clear_memoized
        clear_memoization(:issue_minimum_id)
        clear_memoization(:issue_maximum_id)
        clear_memoization(:user_minimum_id)
        clear_memoization(:user_maximum_id)
        clear_memoization(:unique_visit_service)
        clear_memoization(:deployment_minimum_id)
        clear_memoization(:deployment_maximum_id)
        clear_memoization(:approval_merge_request_rule_minimum_id)
        clear_memoization(:approval_merge_request_rule_maximum_id)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def cluster_applications_user_distinct_count(applications, time_period)
        distinct_count(applications.where(time_period).available.joins(:cluster), 'clusters.user_id')
      end

      def clusters_user_distinct_count(clusters, time_period)
        distinct_count(clusters.where(time_period), :user_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def omniauth_provider_names
        ::Gitlab.config.omniauth.providers.map(&:name)
      end

      # LDAP provider names are set by customers and could include
      # sensitive info (server names, etc). LDAP providers normally
      # don't appear in omniauth providers but filter to ensure
      # no internal details leak via usage ping.
      def filtered_omniauth_provider_names
        omniauth_provider_names.reject { |name| name.starts_with?('ldap') }
      end

      def deployment_count(relation)
        count relation, start: deployment_minimum_id, finish: deployment_maximum_id
      end
    end
  end
end

Gitlab::UsageData.prepend_if_ee('EE::Gitlab::UsageData')
