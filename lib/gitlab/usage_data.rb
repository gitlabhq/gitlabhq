# frozen_string_literal: true

module Gitlab
  class UsageData
    APPROXIMATE_COUNT_MODELS = [Label, MergeRequest, Note, Todo].freeze

    class << self
      def data(force_refresh: false)
        Rails.cache.fetch('usage_data', force: force_refresh, expires_in: 2.weeks) do
          uncached_data
        end
      end

      def uncached_data
        license_usage_data.merge(system_usage_data)
                          .merge(features_usage_data)
                          .merge(components_usage_data)
                          .merge(cycle_analytics_usage_data)
                          .merge(usage_counters)
      end

      def to_json(force_refresh: false)
        data(force_refresh: force_refresh).to_json
      end

      def license_usage_data
        usage_data = {
          uuid: Gitlab::CurrentSettings.uuid,
          hostname: Gitlab.config.gitlab.host,
          version: Gitlab::VERSION,
          installation_type: installation_type,
          active_user_count: count(User.active),
          recorded_at: Time.now,
          edition: 'CE'
        }

        usage_data
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop: disable CodeReuse/ActiveRecord
      def system_usage_data
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
            clusters_disabled: count(::Clusters::Cluster.disabled),
            project_clusters_disabled: count(::Clusters::Cluster.disabled.project_type),
            group_clusters_disabled: count(::Clusters::Cluster.disabled.group_type),
            clusters_platforms_gke: count(::Clusters::Cluster.gcp_installed.enabled),
            clusters_platforms_user: count(::Clusters::Cluster.user_provided.enabled),
            clusters_applications_helm: count(::Clusters::Applications::Helm.available),
            clusters_applications_ingress: count(::Clusters::Applications::Ingress.available),
            clusters_applications_cert_managers: count(::Clusters::Applications::CertManager.available),
            clusters_applications_prometheus: count(::Clusters::Applications::Prometheus.available),
            clusters_applications_runner: count(::Clusters::Applications::Runner.available),
            clusters_applications_knative: count(::Clusters::Applications::Knative.available),
            in_review_folder: count(::Environment.in_review_folder),
            groups: count(Group),
            issues: count(Issue),
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
            protected_branches: count(ProtectedBranch),
            releases: count(Release),
            remote_mirrors: count(RemoteMirror),
            snippets: count(Snippet),
            suggestions: count(Suggestion),
            todos: count(Todo),
            uploads: count(Upload),
            web_hooks: count(WebHook)
          }
          .merge(services_usage)
          .merge(approximate_counts)
        }.tap do |data|
          data[:counts][:user_preferences] = user_preferences_usage
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def cycle_analytics_usage_data
        Gitlab::CycleAnalytics::UsageData.new.to_json
      end

      def features_usage_data
        features_usage_data_ce
      end

      def features_usage_data_ce
        {
          container_registry_enabled: Gitlab.config.registry.enabled,
          gitlab_shared_runners_enabled: Gitlab.config.gitlab_ci.shared_runners_enabled,
          gravatar_enabled: Gitlab::CurrentSettings.gravatar_enabled?,
          influxdb_metrics_enabled: Gitlab::Metrics.influx_metrics_enabled?,
          ldap_enabled: Gitlab.config.ldap.enabled,
          mattermost_enabled: Gitlab.config.mattermost.enabled,
          omniauth_enabled: Gitlab::Auth.omniauth_enabled?,
          prometheus_metrics_enabled: Gitlab::Metrics.prometheus_metrics_enabled?,
          reply_by_email_enabled: Gitlab::IncomingEmail.enabled?,
          signup_enabled: Gitlab::CurrentSettings.allow_signup?
        }
      end

      # @return [Hash<Symbol, Integer>]
      def usage_counters
        usage_data_counters.map(&:totals).reduce({}) { |a, b| a.merge(b) }
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
         Gitlab::UsageDataCounters::SourceCodeCounter
        ]
      end

      def components_usage_data
        {
          git: { version: Gitlab::Git.version },
          gitaly: { version: Gitaly::Server.all.first.server_version, servers: Gitaly::Server.count, filesystems: Gitaly::Server.filesystems },
          gitlab_pages: { enabled: Gitlab.config.pages.enabled, version: Gitlab::Pages::VERSION },
          database: { adapter: Gitlab::Database.adapter_name, version: Gitlab::Database.version }
        }
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def services_usage
        types = {
          SlackService: :projects_slack_notifications_active,
          SlackSlashCommandsService: :projects_slack_slash_active,
          PrometheusService: :projects_prometheus_active
        }

        results = count(Service.unscoped.where(type: types.keys, active: true).group(:type), fallback: Hash.new(-1))
        types.each_with_object({}) { |(klass, key), response| response[key] = results[klass.to_s] || 0 }
          .merge(jira_usage)
      end

      def jira_usage
        # Jira Cloud does not support custom domains as per https://jira.atlassian.com/browse/CLOUD-6999
        # so we can just check for subdomains of atlassian.net
        services = count(
          Service.unscoped.where(type: :JiraService, active: true)
            .group("CASE WHEN properties LIKE '%.atlassian.net%' THEN 'cloud' ELSE 'server' END"),
          fallback: Hash.new(-1)
        )

        {
          projects_jira_server_active: services['server'] || 0,
          projects_jira_cloud_active: services['cloud'] || 0,
          projects_jira_active: services['server'] == -1 ? -1 : services.values.sum
        }
      end

      def user_preferences_usage
        {} # augmented in EE
      end

      def count(relation, fallback: -1)
        relation.count
      rescue ActiveRecord::StatementInvalid
        fallback
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def approximate_counts
        approx_counts = Gitlab::Database::Count.approximate_counts(APPROXIMATE_COUNT_MODELS)

        APPROXIMATE_COUNT_MODELS.each_with_object({}) do |model, result|
          key = model.name.underscore.pluralize.to_sym

          result[key] = approx_counts[model] || -1
        end
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
