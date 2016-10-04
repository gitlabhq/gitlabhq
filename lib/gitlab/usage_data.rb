module Gitlab
  class UsageData
    class << self
      def data(force_refresh = false)
        Rails.cache.fetch('usage_data', force: force_refresh) { uncached_data }
      end

      def uncached_data
        license_usage_data.merge(system_usage_data)
      end

      def to_json(force_refresh = false)
        data(force_refresh).to_json
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
            geo_nodes: GeoNode.count,
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
            pushes: Event.code_push.count,
            pages_domains: PagesDomain.count,
            projects: Project.count,
            protected_branches: ProtectedBranch.count,
            releases: Release.count,
            remote_mirrors: RemoteMirror.count,
            services: Service.where(active: true).count,
            snippets: Snippet.count,
            todos: Todo.count,
            web_hooks: WebHook.count
          }
        }
      end

      def license_usage_data
        usage_data = { version: Gitlab::VERSION,
                       active_user_count: User.active.count }
        license = ::License.current

        if license
          usage_data[:license_md5] = Digest::MD5.hexdigest(license.data)
          usage_data[:historical_max_users] = ::HistoricalData.max_historical_user_count
          usage_data[:licensee] = license.licensee
          usage_data[:license_user_count] = license.user_count
          usage_data[:license_starts_at] = license.starts_at
          usage_data[:license_expires_at] = license.expires_at
          usage_data[:license_add_ons] = license.add_ons
          usage_data[:recorded_at] = Time.now
        end

        usage_data
      end
    end
  end
end
