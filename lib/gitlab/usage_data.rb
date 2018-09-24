module Gitlab
  class UsageData
    class << self
      def data(force_refresh: false)
        Rails.cache.fetch('usage_data', force: force_refresh, expires_in: 2.weeks) { uncached_data }
      end

      def uncached_data
        license_usage_data.merge(system_usage_data)
                          .merge(features_usage_data)
                          .merge(components_usage_data)
                          .merge(cycle_analytics_usage_data)
      end

      def to_json(force_refresh: false)
        data(force_refresh: force_refresh).to_json
      end

      def license_usage_data
        usage_data = {
          uuid: Gitlab::CurrentSettings.uuid,
          hostname: Gitlab.config.gitlab.host,
          version: Gitlab::VERSION,
          installation_type: Gitlab::INSTALLATION_TYPE,
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
            environments: count(::Environment),
            clusters: count(::Clusters::Cluster),
            clusters_enabled: count(::Clusters::Cluster.enabled),
            clusters_disabled: count(::Clusters::Cluster.disabled),
            clusters_platforms_gke: count(::Clusters::Cluster.gcp_installed.enabled),
            clusters_platforms_user: count(::Clusters::Cluster.user_provided.enabled),
            clusters_applications_helm: count(::Clusters::Applications::Helm.installed),
            clusters_applications_ingress: count(::Clusters::Applications::Ingress.installed),
            clusters_applications_prometheus: count(::Clusters::Applications::Prometheus.installed),
            clusters_applications_runner: count(::Clusters::Applications::Runner.installed),
            in_review_folder: count(::Environment.in_review_folder),
            groups: count(Group),
            issues: count(Issue),
            keys: count(Key),
            label_lists: count(List.label),
            labels: count(Label),
            lfs_objects: count(LfsObject),
            merge_requests: count(MergeRequest),
            milestone_lists: count(List.milestone),
            milestones: count(Milestone),
            notes: count(Note),
            pages_domains: count(PagesDomain),
            projects: count(Project),
            projects_imported_from_github: count(Project.where(import_type: 'github')),
            protected_branches: count(ProtectedBranch),
            releases: count(Release),
            remote_mirrors: count(RemoteMirror),
            snippets: count(Snippet),
            todos: count(Todo),
            uploads: count(Upload),
            web_hooks: count(WebHook)
          }.merge(services_usage)
        }
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
          ldap_enabled: Gitlab.config.ldap.enabled,
          mattermost_enabled: Gitlab.config.mattermost.enabled,
          omniauth_enabled: Gitlab::Auth.omniauth_enabled?,
          reply_by_email_enabled: Gitlab::IncomingEmail.enabled?,
          signup_enabled: Gitlab::CurrentSettings.allow_signup?
        }
      end

      def components_usage_data
        {
          gitlab_pages: { enabled: Gitlab.config.pages.enabled, version: Gitlab::Pages::VERSION },
          git: { version: Gitlab::Git.version },
          database: { adapter: Gitlab::Database.adapter_name, version: Gitlab::Database.version }
        }
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def services_usage
        types = {
          JiraService: :projects_jira_active,
          SlackService: :projects_slack_notifications_active,
          SlackSlashCommandsService: :projects_slack_slash_active,
          PrometheusService: :projects_prometheus_active
        }

        results = count(Service.unscoped.where(type: types.keys, active: true).group(:type), fallback: Hash.new(-1))
        types.each_with_object({}) { |(klass, key), response| response[key] = results[klass.to_s] || 0 }
      end

      def count(relation, fallback: -1)
        relation.count
      rescue ActiveRecord::StatementInvalid
        fallback
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
