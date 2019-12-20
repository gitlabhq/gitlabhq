# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      class InstallCommand
        include BaseCommand
        include ClientCommand

        attr_reader :name, :files, :chart, :repository, :preinstall, :postinstall
        attr_accessor :version

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
            preinstall,
            install_command,
            postinstall
          ].compact.join("\n")
        end

        def rbac?
          @rbac
        end

        private

        # Uses `helm upgrade --install` which means we can use this for both
        # installation and uprade of applications
        def install_command
          command = ['helm', 'upgrade', name, chart] +
            install_flag +
            reset_values_flag +
            tls_flags_if_remote_tiller +
            optional_version_flag +
            rbac_create_flag +
            namespace_flag +
            value_flag

          command.shelljoin
        end

        def install_flag
          ['--install']
        end

        def reset_values_flag
          ['--reset-values']
        end

        def value_flag
          ['-f', "/data/helm/#{name}/config/values.yaml"]
        end

        def namespace_flag
          ['--namespace', Gitlab::Kubernetes::Helm::NAMESPACE]
        end

        def rbac_create_flag
          if rbac?
            %w[--set rbac.create=true,rbac.enabled=true]
          else
            %w[--set rbac.create=false,rbac.enabled=false]
          end
        end

        def optional_version_flag
          return [] unless version

          ['--version', version]
        end
      end
    end
  end
end
