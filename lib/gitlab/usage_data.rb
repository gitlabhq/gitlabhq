module Gitlab
  class UsageData
    include Gitlab::CurrentSettings

    class << self
      def data(force_refresh: false)
        Rails.cache.fetch('usage_data', force: force_refresh, expires_in: 2.weeks) { uncached_data }
      end

      def uncached_data
        license_usage_data.merge(system_usage_data)
      end

      def to_json(force_refresh: false)
        data(force_refresh: force_refresh).to_json
      end

      def system_usage_data
        {
          counts: {
            boards: Board.count,
            ci_builds: ::Ci::Build.count,
            ci_internal_pipelines: ::Ci::Pipeline.internal.count,
            ci_external_pipelines: ::Ci::Pipeline.external.count,
            ci_runners: ::Ci::Runner.count,
            ci_triggers: ::Ci::Trigger.count,
            ci_pipeline_schedules: ::Ci::PipelineSchedule.count,
            deploy_keys: DeployKey.count,
            deployments: Deployment.count,
            environments: ::Environment.count,
            in_review_folder: ::Environment.in_review_folder.count,
            groups: Group.count,
            issues: Issue.count,
            keys: Key.count,
            labels: Label.count,
            lfs_objects: LfsObject.count,
            merge_requests: MergeRequest.count,
            milestones: Milestone.count,
            notes: Note.count,
            pages_domains: PagesDomain.count,
            projects: Project.count,
            projects_imported_from_github: Project.where(import_type: 'github').count,
            protected_branches: ProtectedBranch.count,
            releases: Release.count,
            snippets: Snippet.count,
            todos: Todo.count,
            uploads: Upload.count,
            web_hooks: WebHook.count
          }.merge(services_usage)
        }
      end

      def license_usage_data
        usage_data = {
          uuid: current_application_settings.uuid,
          hostname: Gitlab.config.gitlab.host,
          version: Gitlab::VERSION,
          active_user_count: User.active.count,
          recorded_at: Time.now,
          mattermost_enabled: Gitlab.config.mattermost.enabled,
          edition: 'CE'
        }

        usage_data
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
