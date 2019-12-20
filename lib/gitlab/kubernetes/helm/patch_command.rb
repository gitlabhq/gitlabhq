# frozen_string_literal: true

# PatchCommand is for updating values in installed charts without overwriting
# existing values.
module Gitlab
  module Kubernetes
    module Helm
      class PatchCommand
        include BaseCommand
        include ClientCommand

        attr_reader :name, :files, :chart, :repository
        attr_accessor :version

        def initialize(name:, chart:, files:, rbac:, version:, repository: nil)
          # version is mandatory to prevent chart mismatches
          # we do not want our values interpreted in the context of the wrong version
          raise ArgumentError, 'version is required' if version.blank?

          @name = name
          @chart = chart
          @version = version
          @rbac = rbac
          @files = files
          @repository = repository
        end

        def generate_script
          super + [
            init_command,
            wait_for_tiller_command,
            repository_command,
            repository_update_command,
            upgrade_command
          ].compact.join("\n")
        end

        def rbac?
          @rbac
        end

        private

        def upgrade_command
          command = ['helm', 'upgrade', name, chart] +
            reuse_values_flag +
            tls_flags_if_remote_tiller +
            version_flag +
            namespace_flag +
            value_flag

          command.shelljoin
        end

        def reuse_values_flag
          ['--reuse-values']
        end

        def value_flag
          ['-f', "/data/helm/#{name}/config/values.yaml"]
        end

        def namespace_flag
          ['--namespace', Gitlab::Kubernetes::Helm::NAMESPACE]
        end

        def version_flag
          ['--version', version]
        end
      end
    end
  end
end
