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
            ci_pipelines: ::Ci::Pipeline.count,
            ci_runners: ::Ci::Runner.count,
            ci_triggers: ::Ci::Trigger.count,
            ci_pipeline_schedules: ::Ci::PipelineSchedule.count,
            deploy_keys: DeployKey.count,
            deployments: Deployment.count,
            environments: Environment.count,
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
            projects_prometheus_active: PrometheusService.active.count,
            protected_branches: ProtectedBranch.count,
            releases: Release.count,
            services: Service.where(active: true).count,
            snippets: Snippet.count,
            todos: Todo.count,
            uploads: Upload.count,
            web_hooks: WebHook.count
          }
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
    end
  end
end
