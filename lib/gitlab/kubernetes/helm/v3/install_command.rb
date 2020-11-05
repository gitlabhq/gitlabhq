# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      module V3
        class InstallCommand < BaseCommand
          attr_reader :chart, :repository, :preinstall, :postinstall
          attr_accessor :version

          def initialize(chart:, version: nil, repository: nil, preinstall: nil, postinstall: nil, **args)
            super(**args)
            @chart = chart
            @version = version
            @repository = repository
            @preinstall = preinstall
            @postinstall = postinstall
          end

          def generate_script
            super + [
              repository_command,
              repository_update_command,
              preinstall,
              install_command,
              postinstall
            ].compact.join("\n")
          end

          private

          # Uses `helm upgrade --install` which means we can use this for both
          # installation and uprade of applications
          def install_command
            command = ['helm', 'upgrade', name, chart] +
                      install_flag +
                      rollback_support_flag +
                      reset_values_flag +
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

          def rollback_support_flag
            ['--atomic', '--cleanup-on-fail']
          end
        end
      end
    end
  end
end
