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

      def data(force_refresh: false)
        Rails.cache.fetch('usage_data', force: force_refresh, expires_in: 2.weeks) do
          uncached_data
        end
      end

      def uncached_data
        license_usage_data
          .merge(system_usage_data)
          .merge(features_usage_data)
          .merge(components_usage_data)
          .merge(cycle_analytics_usage_data)
          .merge(object_store_usage_data)
          .merge(recording_ce_finish_data)
      end

      def to_json(force_refresh: false)
        data(force_refresh: force_refresh).to_json
      end

      def license_usage_data
        {
          recorded_at: Time.now, # should be calculated very first
          uuid: alt_usage_data { Gitlab::CurrentSettings.uuid },
          hostname: alt_usage_data { Gitlab.config.gitlab.host },
          version: alt_usage_data { Gitlab::VERSION },
          installation_type: alt_usage_data { installation_type },
          active_user_count: count(User.active),
          edition: 'CE'
        }
      end

      def recording_ce_finish_data
        {
          recording_ce_finished_at: Time.now
        }
      end

      # rubocop: disable Metrics/AbcSize
      # rubocop: disable CodeReuse/ActiveRecord
      def system_usage_data
        alert_bot_incident_count = count(::Issue.authored(::User.alert_bot))

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
            deployments: count(Deployment),
            successful_deployments: count(Deployment.success),
            failed_deployments: count(Deployment.failed),
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
            clusters_management_project: count(::Clusters::Cluster.with_management_project),
            in_review_folder: count(::Environment.in_review_folder),
            grafana_integrated_projects: count(GrafanaIntegration.enabled),
            groups: count(Group),
            issues: count(Issue),
            issues_created_from_gitlab_error_tracking_ui: count(SentryIssue),
            issues_with_associated_zoom_link: count(ZoomMeeting.added_to_issue),
            issues_using_zoom_quick_actions: distinct_count(ZoomMeeting, :issue_id),
            issues_with_embedded_grafana_charts_approx: grafana_embed_usage_data,
            issues_created_gitlab_alerts: count(Issue.with_alert_management_alerts.not_authored_by(::User.alert_bot)),
            incident_issues: alert_bot_incident_count,
            alert_bot_incident_issues: alert_bot_incident_count,
            incident_labeled_issues: count(::Issue.with_label_attributes(IncidentManagement::CreateIssueService::INCIDENT_LABEL)),
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
            snippets: count(Snippet),
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
          )
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord
      # rubocop: enable Metrics/AbcSize

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
          container_registry_enabled: alt_usage_data(fallback: nil) { Gitlab.config.registry.enabled },
          dependency_proxy_enabled: Gitlab.config.try(:dependency_proxy)&.enabled,
          gitlab_shared_runners_enabled: alt_usage_data(fallback: nil) { Gitlab.config.gitlab_ci.shared_runners_enabled },
          gravatar_enabled: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.gravatar_enabled? },
          ldap_enabled: alt_usage_data(fallback: nil) { Gitlab.config.ldap.enabled },
          mattermost_enabled: alt_usage_data(fallback: nil) { Gitlab.config.mattermost.enabled },
          omniauth_enabled: alt_usage_data(fallback: nil) { Gitlab::Auth.omniauth_enabled? },
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
        results = Service.available_services_names.without('jira').each_with_object({}) do |service_name, response|
          response["projects_#{service_name}_active".to_sym] = count(Service.active.where(template: false, type: "#{service_name}_service".camelize))
        end

        # Keep old Slack keys for backward compatibility, https://gitlab.com/gitlab-data/analytics/issues/3241
        results[:projects_slack_notifications_active] = results[:projects_slack_active]
        results[:projects_slack_slash_active] = results[:projects_slack_slash_commands_active]

        results.merge(jira_usage).merge(jira_import_usage)
      end

      def jira_usage
        # Jira Cloud does not support custom domains as per https://jira.atlassian.com/browse/CLOUD-6999
        # so we can just check for subdomains of atlassian.net

        results = {
          projects_jira_server_active: 0,
          projects_jira_cloud_active: 0,
          projects_jira_active: 0
        }

        Service.active
          .by_type(:JiraService)
          .includes(:jira_tracker_data)
          .find_in_batches(batch_size: BATCH_SIZE) do |services|
          counts = services.group_by do |service|
            # TODO: Simplify as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
            service_url = service.data_fields&.url || (service.properties && service.properties['url'])
            service_url&.include?('.atlassian.net') ? :cloud : :server
          end

          results[:projects_jira_server_active] += counts[:server].count if counts[:server]
          results[:projects_jira_cloud_active] += counts[:cloud].count if counts[:cloud]
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

      def installation_type
        if Rails.env.production?
          Gitlab::INSTALLATION_TYPE
        else
          "gitlab-development-kit"
        end
      end
    end
  end
end

Gitlab::UsageData.prepend_if_ee('EE::Gitlab::UsageData')
