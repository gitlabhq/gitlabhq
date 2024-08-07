# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    class DefaultSettings
      UNDEFINED = nil

      # ALL REMOTE DEVELOPMENT SETTINGS MUST BE DECLARED HERE.
      # See ../README.md for more details.
      # @return [Hash]
      def self.default_settings
        {
          # NOTE: default_branch_name is not actually used by Remote Development, it is simply a placeholder to drive
          #       the logic for reading settings from ::Gitlab::CurrentSettings. It can be replaced when there is an
          #       actual Remote Development entry in ::Gitlab::CurrentSettings.
          default_branch_name: [UNDEFINED, String],
          default_max_hours_before_termination: [24, Integer],
          max_hours_before_termination_limit: [120, Integer],
          project_cloner_image: ['alpine/git:2.36.3', String],
          tools_injector_image: [
            "registry.gitlab.com/gitlab-org/remote-development/gitlab-workspaces-tools:2.0.0", String
          ],
          full_reconciliation_interval_seconds: [3600, Integer],
          partial_reconciliation_interval_seconds: [10, Integer],
          workspaces_quota: [-1, Integer],
          workspaces_per_user_quota: [-1, Integer],
          network_policy_egress: [[{
            allow: "0.0.0.0/0",
            except: %w[10.0.0.0/8 172.16.0.0/12 192.168.0.0/16]
          }], Array],
          default_resources_per_workspace_container: [{}, Hash],
          max_resources_per_workspace: [{}, Hash],
          gitlab_workspaces_proxy_namespace: [{}, Hash],
          network_policy_enabled: [true, :Boolean]
        }
      end
    end
  end
end
