# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Utils
        # Run tar command to create or extract content from an archive
        class Tar
          DEFAULT_EXCLUDES = ['lost+found'].freeze

          # Returns the version of tar command available
          #
          # @return [String] the first line of `--version` output
          def version
            version = Shell::Command.new(cmd, '--version').capture.stdout.dup
            version.force_encoding('locale').split("\n").first
          end

          def cmd
            @cmd ||= if gtar_available?
                       # In BSD/Darwin we can get GNU tar by running 'gtar' instead
                       'gtar'
                     else
                       'tar'
                     end
          end

          # Tar's Shell::Command that can be used directly or combined with a Shell::Pipeline
          #
          # @param [String|Pathname] archive_file the archive file with full path (used by tar's --file option)
          # @param [String|Pathname] target_directory the path to evaluate targets (used by tar's --directory option)
          # @param [String|Pathname|Array] target what will be packed into the archive
          # @param [Array<String>] excludes targets that will be excluded from the backup
          # @return [Gitlab::Backup::Cli::Shell::Command]
          def pack_cmd(archive_file:, target_directory:, target:, excludes: [])
            tar_args = []
            tar_args += build_exclude_patterns(*DEFAULT_EXCLUDES)
            tar_args += build_exclude_targets(*excludes)
            tar_args += %W[
              --directory=#{target_directory}
              --create
              --file=#{archive_file}
            ]

            # Ensure single target or multiple targets are converted to string before adding to args,
            # to avoid type conversion errors with Pathname
            tar_args += Array(target).map(&:to_s)

            Shell::Command.new(cmd, *tar_args)
          end

          def pack_from_stdin_cmd(target_directory:, target:, excludes: [])
            pack_cmd(
              archive_file: '-', # use stdin as list of files
              target_directory: target_directory,
              target: target,
              excludes: excludes)
          end

          # @param [Object] archive_file
          # @param [Object] target_directory
          # @return [Gitlab::Backup::Cli::Shell::Command]
          def extract_cmd(archive_file:, target_directory:)
            tar_args = %W[
              --unlink-first
              --recursive-unlink
              --directory=#{target_directory}
              --extract
              --file=#{archive_file}
            ]

            Shell::Command.new(cmd, *tar_args)
          end

          def extract_from_stdin_cmd(target_directory:)
            extract_cmd(archive_file: '-', # use stdin as file source content
              target_directory: target_directory)
          end

          private

          def build_exclude_patterns(*patterns)
            patterns.map { |pattern| %(--exclude=#{pattern}) }
          end

          def build_exclude_targets(*targets)
            targets.map { |target| %(--exclude=./#{target}) }
          end

          def gtar_available?
            Dependencies.executable_exist?('gtar')
          end
        end
      end
    end
  end
end
