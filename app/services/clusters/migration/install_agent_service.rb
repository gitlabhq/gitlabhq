# frozen_string_literal: true

module Clusters
  module Migration
    class InstallAgentService
      NAMESPACE_LENGTH_LIMIT = 63

      delegate :cluster, :agent, to: :migration, private: true
      delegate :kubeclient, to: :cluster, private: true

      def initialize(migration)
        @migration = migration
      end

      def execute
        return unless can_install_agent?

        kubeclient.create_or_update_service_account(service_account_resource)
        kubeclient.create_or_update_cluster_role_binding(cluster_role_binding_resource)
        kubeclient.create_pod(helm_install_pod_resource)

        update_status!(:success)
      rescue StandardError => e
        update_status!(:error, message: e.class)
      end

      private

      attr_reader :migration

      def can_install_agent?
        migration.agent_install_status_pending? && cluster.connection_status == :connected
      end

      def service_account_name
        'install-gitlab-agent'
      end

      def service_account_namespace
        'default'
      end

      def service_account_resource
        Gitlab::Kubernetes::ServiceAccount.new(service_account_name, service_account_namespace).generate
      end

      def cluster_role_binding_resource
        subjects = [{ kind: 'ServiceAccount', name: service_account_name, namespace: service_account_namespace }]

        Gitlab::Kubernetes::ClusterRoleBinding.new(service_account_name, 'cluster-admin', subjects).generate
      end

      def helm_install_pod_resource
        ::Kubeclient::Resource.new(metadata: helm_install_pod_metadata, spec: helm_install_pod_spec)
      end

      def helm_install_pod_metadata
        {
          name: service_account_name,
          namespace: service_account_namespace
        }
      end

      def helm_install_pod_spec
        {
          containers: [{
            name: 'helm',
            image: helm_install_image,
            env: [{
              name: 'INSTALL_COMMAND', value: install_command
            }],
            command: %w[/bin/sh],
            args: %w[-c $(INSTALL_COMMAND)]
          }],
          serviceAccountName: service_account_name,
          restartPolicy: 'Never'
        }
      end

      def add_repository_command
        'helm repo add gitlab https://charts.gitlab.io'
      end

      def update_repository_command
        'helm repo update'
      end

      def install_command
        [
          add_repository_command,
          update_repository_command,
          helm_install_command
        ].compact.join("\n")
      end

      def helm_install_command
        [
          'helm',
          'upgrade',
          '--install',
          agent.name,
          'gitlab/gitlab-agent',
          *namespace_flag,
          '--create-namespace',
          *image_tag_flag,
          *token_flag,
          *kas_address_flag
        ].shelljoin
      end

      def namespace_flag
        ['--namespace', agent_namespace]
      end

      def image_tag_flag
        return if Gitlab.com? # rubocop:todo Gitlab/AvoidGitlabInstanceChecks -- GitLab.com uses the latest version, this check will be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/535030

        ['--set', "image.tag=v#{Gitlab::Kas.install_version_info}"]
      end

      def token_flag
        ['--set', "config.token=#{agent_token}"]
      end

      def kas_address_flag
        ['--set', "config.kasAddress=#{kas_address}"]
      end

      def agent_namespace
        "gitlab-agent-#{agent.name}".first(NAMESPACE_LENGTH_LIMIT).parameterize
      end

      def helm_install_image
        'registry.gitlab.com/gitlab-org/cluster-integration/helm-install-image:helm-3.17.2-kube-1.32.3-alpine-3.21.3'
      end

      def agent_token
        agent.agent_tokens.first.token
      end

      def kas_address
        Gitlab::Kas.external_url
      end

      def update_status!(status, message: nil)
        migration.update!(
          agent_install_status: status,
          agent_install_message: message
        )
      end
    end
  end
end
