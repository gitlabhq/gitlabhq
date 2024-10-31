# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Targets
        class Files < Target
          DEFAULT_EXCLUDE = ['lost+found'].freeze

          attr_reader :excludes

          # @param [String] storage_path
          # @param [Array] excludes
          def initialize(context, storage_path, excludes: [])
            super(context)

            @storage_path = storage_path
            @excludes = excludes
          end

          def dump(destination)
            archive_file = [destination, 'w', 0o600]
            tar_command = Utils::Tar.new.pack_from_stdin_cmd(
              target_directory: storage_realpath,
              target: '.',
              excludes: excludes)

            compression_cmd = Utils::Compression.compression_command

            pipeline = Shell::Pipeline.new(tar_command, compression_cmd)

            result = pipeline.run!(output: archive_file)

            return if success?(result)

            raise Errors::FileBackupError.new(storage_realpath, destination)
          end

          def restore(source)
            # Existing files will be handled in https://gitlab.com/gitlab-org/gitlab/-/issues/499876
            if File.exist?(storage_realpath)
              Output.warning "Ignoring existing files at #{storage_realpath} and continuing restore."
            end

            archive_file = source.to_s
            tar_command = Utils::Tar.new.extract_from_stdin_cmd(target_directory: storage_realpath)

            decompression_cmd = Utils::Compression.decompression_command

            pipeline = Shell::Pipeline.new(decompression_cmd, tar_command)
            result = pipeline.run!(input: archive_file)

            return if success?(result)

            raise Errors::FileRestoreError.new(error_message: result.stderr)
          end

          private

          def success?(result)
            return true if result.success?

            return true if ignore_non_success?(
              result.status_list[1].exitstatus,
              result.stderr
            )

            false
          end

          def noncritical_warning_matcher
            /^g?tar: \.: Cannot mkdir: No such file or directory$/
          end

          def ignore_non_success?(exitstatus, output)
            # tar can exit with nonzero code:
            #  1 - if some files changed (i.e. a CI job is currently writes to log)
            #  2 - if it cannot create `.` directory (see issue https://gitlab.com/gitlab-org/gitlab/-/issues/22442)
            #  http://www.gnu.org/software/tar/manual/html_section/tar_19.html#Synopsis
            #  so check tar status 1 or stderr output against some non-critical warnings
            if exitstatus == 1
              Output.print_info "Ignoring tar exit status 1 'Some files differ': #{output}"
              return true
            end

            # allow tar to fail with other non-success status if output contain non-critical warning
            if noncritical_warning_matcher&.match?(output)
              Output.print_info(
                "Ignoring non-success exit status #{exitstatus} due to output of non-critical warning(s): #{output}")
              return true
            end

            false
          end

          def storage_realpath
            @storage_realpath ||= File.realpath(@storage_path)
          end
        end
      end
    end
  end
end
