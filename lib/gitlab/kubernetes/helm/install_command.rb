# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      class InstallCommand
        include BaseCommand
        include ClientCommand

        attr_reader :name, :files, :chart, :version, :repository, :preinstall, :postinstall

        def initialize(name:, chart:, files:, rbac:, version: nil, repository: nil, preinstall: nil, postinstall: nil)
          @name = name
          @chart = chart
          @version = version
          @rbac = rbac
          @files = files
          @repository = repository
          @preinstall = preinstall
          @postinstall = postinstall
        end

        def generate_script
          super + [
            init_command,
            wait_for_tiller_command,
            repository_command,
            repository_update_command,
            preinstall_command,
            install_command,
            postinstall_command
          ].compact.join("\n")
        end

        def rbac?
          @rbac
        end

        private

        def repository_update_command
          'helm repo update' if repository
        end

        def install_command
          command = ['helm', 'install', chart] + install_command_flags

          command.shelljoin
        end

        def preinstall_command
          preinstall.join("\n") if preinstall
        end

        def postinstall_command
          postinstall.join("\n") if postinstall
        end

        def install_command_flags
          name_flag      = ['--name', name]
          namespace_flag = ['--namespace', Gitlab::Kubernetes::Helm::NAMESPACE]
          value_flag     = ['-f', "/data/helm/#{name}/config/values.yaml"]

          name_flag +
            optional_tls_flags +
            optional_version_flag +
            optional_rbac_create_flag +
            namespace_flag +
            value_flag
        end

        def optional_rbac_create_flag
          return [] unless rbac?

          # jupyterhub helm chart is using rbac.enabled
          #   https://github.com/jupyterhub/zero-to-jupyterhub-k8s/tree/master/jupyterhub
          %w[--set rbac.create=true,rbac.enabled=true]
        end

        def optional_version_flag
          return [] unless version

          ['--version', version]
        end

        def optional_tls_flags
          return [] unless files.key?(:'ca.pem')

          [
            '--tls',
            '--tls-ca-cert', "#{files_dir}/ca.pem",
            '--tls-cert', "#{files_dir}/cert.pem",
            '--tls-key', "#{files_dir}/key.pem"
          ]
        end
      end
    end
  end
end
