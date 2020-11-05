# frozen_string_literal: true

# PatchCommand is for updating values in installed charts without overwriting
# existing values.
module Gitlab
  module Kubernetes
    module Helm
      module V3
        class PatchCommand < BaseCommand
          attr_reader :chart, :repository
          attr_accessor :version

          def initialize(chart:, version:, repository: nil, **args)
            super(**args)

            # version is mandatory to prevent chart mismatches
            # we do not want our values interpreted in the context of the wrong version
            raise ArgumentError, 'version is required' if version.blank?

            @chart = chart
            @version = version
            @repository = repository
          end

          def generate_script
            super + [
              repository_command,
              repository_update_command,
              upgrade_command
            ].compact.join("\n")
          end

          private

          def upgrade_command
            command = ['helm', 'upgrade', name, chart] +
                      reuse_values_flag +
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

          def version_flag
            ['--version', version]
          end
        end
      end
    end
  end
end
