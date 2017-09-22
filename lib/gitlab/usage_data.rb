module Gitlab
  class UsageData
    class << self
      include Gitlab::CurrentSettings

      def data(force_refresh: false)
        Rails.cache.fetch('usage_data', force: force_refresh, expires_in: 2.weeks) { uncached_data }
      end

      def uncached_data
        license_usage_data.merge(system_usage_data)
                          .merge(features_usage_data)
                          .merge(components_usage_data)
      end

      def to_json(force_refresh: false)
        data(force_refresh: force_refresh).to_json
      end

      def license_usage_data
        usage_data = {
          uuid: current_application_settings.uuid,
          hostname: Gitlab.config.gitlab.host,
          version: Gitlab::VERSION,
          active_user_count: User.active.count,
          recorded_at: Time.now,
          mattermost_enabled: Gitlab.config.mattermost.enabled,
          edition: 'EE'
        }

        license = ::License.current

        if license
          usage_data[:edition] = license_edition(license.plan)
          usage_data[:license_md5] = license.md5
          usage_data[:historical_max_users] = ::HistoricalData.max_historical_user_count
          usage_data[:licensee] = license.licensee
          usage_data[:license_user_count] = license.restricted_user_count
          usage_data[:license_starts_at] = license.starts_at
          usage_data[:license_expires_at] = license.expires_at
          usage_data[:license_plan] = license.plan
          usage_data[:license_add_ons] = license.add_ons
        end

        usage_data
      end

      def system_usage_data
        {
          counts: {
            boards: Board.count,
            ci_builds: ::Ci::Build.count,
            ci_internal_pipelines: ::Ci::Pipeline.internal.count,
            ci_external_pipelines: ::Ci::Pipeline.external.count,
            ci_pipeline_config_auto_devops: ::Ci::Pipeline.auto_devops_source.count,
            ci_pipeline_config_repository: ::Ci::Pipeline.repository_source.count,
            ci_runners: ::Ci::Runner.count,
            ci_triggers: ::Ci::Trigger.count,
            ci_pipeline_schedules: ::Ci::PipelineSchedule.count,
            auto_devops_enabled: ::ProjectAutoDevops.enabled.count,
            auto_devops_disabled: ::ProjectAutoDevops.disabled.count,
            deploy_keys: DeployKey.count,
            deployments: Deployment.count,
            environments: ::Environment.count,
            geo_nodes: GeoNode.count,
            in_review_folder: ::Environment.in_review_folder.count,
            groups: Group.count,
            issues: Issue.count,
            keys: Key.count,
            labels: Label.count,
            ldap_group_links: LdapGroupLink.count,
            ldap_keys: LDAPKey.count,
            ldap_users: User.ldap.count,
            lfs_objects: LfsObject.count,
            merge_requests: MergeRequest.count,
            milestones: Milestone.count,
            notes: Note.count,
            pages_domains: PagesDomain.count,
            projects: Project.count,
            projects_imported_from_github: Project.where(import_type: 'github').count,
            protected_branches: ProtectedBranch.count,
            releases: Release.count,
            remote_mirrors: RemoteMirror.count,
            services: Service.where(active: true).count,
            snippets: Snippet.count,
            todos: Todo.count,
            uploads: Upload.count,
            web_hooks: WebHook.count
          }.merge(service_desk_counts).merge(services_usage)
        }
      end

      def service_desk_counts
        return {} unless ::License.feature_available?(:service_desk)

        projects_with_service_desk = Project.where(service_desk_enabled: true)

        {
          service_desk_enabled_projects: projects_with_service_desk.count,
          service_desk_issues: Issue.where(project: projects_with_service_desk,
                                           author: User.support_bot,
                                           confidential: true).count
        }
      end

      def features_usage_data
        features_usage_data_ce.merge(features_usage_data_ee)
      end

      def features_usage_data_ce
        {
          signup: current_application_settings.signup_enabled?,
          ldap: Gitlab.config.ldap.enabled,
          gravatar: current_application_settings.gravatar_enabled?,
          omniauth: Gitlab.config.omniauth.enabled,
          reply_by_email: Gitlab::IncomingEmail.enabled?,
          container_registry: Gitlab.config.registry.enabled,
          gitlab_shared_runners: Gitlab.config.gitlab_ci.shared_runners_enabled
        }
      end

      def features_usage_data_ee
        {
          elasticsearch: current_application_settings.elasticsearch_search?,
          geo: Gitlab::Geo.enabled?
        }
      end

      def components_usage_data
        {
          gitlab_pages: { enabled: Gitlab.config.pages.enabled, version: Gitlab::Pages::VERSION },
          git: { version: Gitlab::Git.version },
          database: { adapter: Gitlab::Database.adapter_name, version: Gitlab::Database.version }
        }
      end

      def license_edition(plan)
        case plan
        when 'premium'
          'EEP'
        when 'starter'
          'EES'
        else # Older licenses
          'EE'
        end
      end

      def services_usage
        types = {
          JiraService: :projects_jira_active,
          SlackService: :projects_slack_notifications_active,
          SlackSlashCommandsService: :projects_slack_slash_active,
          PrometheusService: :projects_prometheus_active
        }

        results = Service.unscoped.where(type: types.keys, active: true).group(:type).count
        results.each_with_object({}) { |(key, value), response| response[types[key.to_sym]] = value  }
      end
    end
  end
end
