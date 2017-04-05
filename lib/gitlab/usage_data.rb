module Gitlab
  class UsageData
    class << self
      def data
        Rails.cache.fetch('usage_data', expires_in: 1.hour) { uncached_data }
      end

      def uncached_data
        license_usage_data.merge(system_usage_data)
      end

      def to_json
        data.to_json
      end

      def system_usage_data
        {
          counts: {
            boards: Board.count,
            ci_builds: ::Ci::Build.count,
            ci_pipelines: ::Ci::Pipeline.count,
            ci_runners: ::Ci::Runner.count,
            ci_triggers: ::Ci::Trigger.count,
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
            pushes: Event.code_push.count,
            pages_domains: PagesDomain.count,
            projects: Project.count,
            protected_branches: ProtectedBranch.count,
            releases: Release.count,
            services: Service.where(active: true).count,
            snippets: Snippet.count,
            todos: Todo.count,
            web_hooks: WebHook.count
          }
        }
      end

      def license_usage_data
        usage_data = { version: Gitlab::VERSION,
                       active_user_count: User.active.count,
                       recorded_at: Time.now }

        usage_data
      end
    end
  end
end
