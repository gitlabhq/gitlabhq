module Gitlab
  module Kubernetes
    module Helm
      class InitCommand
        include BaseCommand

        attr_reader :name, :files

        def initialize(name:, files:, rbac:)
          @name = name
          @files = files
          @rbac = rbac
        end

        def generate_script
          super + [
            init_helm_command
          ].join("\n")
        end

        def rbac?
          @rbac
        end

        def service_account_resource
          return unless rbac?

          Gitlab::Kubernetes::ServiceAccount.new(service_account_name, namespace).generate
        end

        def cluster_role_binding_resource
          return unless rbac?

          subjects = [{ kind: 'ServiceAccount', name: service_account_name, namespace: namespace }]

          Gitlab::Kubernetes::ClusterRoleBinding.new(
            cluster_role_binding_name,
            cluster_role_name,
            subjects
          ).generate
        end

        private

        def init_helm_command
          command = %w[helm init] + init_command_flags

          command.shelljoin + " >/dev/null\n"
        end

        def init_command_flags
          tls_flags + optional_service_account_flag
        end

        def tls_flags
          [
            '--tiller-tls',
            '--tiller-tls-verify',
            '--tls-ca-cert', "#{files_dir}/ca.pem",
            '--tiller-tls-cert', "#{files_dir}/cert.pem",
            '--tiller-tls-key', "#{files_dir}/key.pem"
          ]
        end

        def optional_service_account_flag
          return [] unless rbac?

          ['--service-account', service_account_name]
        end

        def cluster_role_binding_name
          Gitlab::Kubernetes::Helm::CLUSTER_ROLE_BINDING
        end

        def cluster_role_name
          Gitlab::Kubernetes::Helm::CLUSTER_ROLE
        end
      end
    end
  end
end
