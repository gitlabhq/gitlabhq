# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Utils
        class PoolRepositories
          PoolReinitializationResult = Struct.new(:disk_path, :status, :error_message, keyword_init: true)

          attr_reader :gitlab_basepath

          def initialize(gitlab_basepath:)
            @gitlab_basepath = gitlab_basepath
          end

          def reinitialize!
            Gitlab::Backup::Cli::Output.info "Reinitializing object pools..."

            rake = build_reset_task
            rake.capture_each do |stream, output|
              next Gitlab::Backup::Cli::Output.warning output if stream == :stderr

              pool = parse_pool_results(output)
              next Gitlab::Backup::Cli::Output.warning "Failed to parse: #{output}" unless pool

              case pool.status.to_sym
              when :scheduled
                Gitlab::Backup::Cli::Output.success "Object pool #{pool.disk_path}..."
              when :skipped
                Gitlab::Backup::Cli::Output.info "Object pool #{pool.disk_path}... [SKIPPED]"
              when :failed
                Gitlab::Backup::Cli::Output.info "Object pool #{pool.disk_path}... [FAILED]"
                Gitlab::Backup::Cli::Output.error(
                  "Object pool #{pool.disk_path} failed to reset (#{pool.error_message})")
              end
            end
          end

          private

          def build_reset_task
            Gitlab::Backup::Cli::Utils::Rake.new(
              'gitlab:backup:repo:reset_pool_repositories',
              chdir: gitlab_basepath)
          end

          def parse_pool_results(line)
            return unless line.start_with?('{') && line.end_with?('}')

            JSON.parse(line, object_class: PoolReinitializationResult)
          rescue JSON::ParserError
            nil
          end
        end
      end
    end
  end
end
