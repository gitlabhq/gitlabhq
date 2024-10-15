# frozen_string_literal: true

require 'open3'

module Backup
  module Targets
    class Files < Target
      extend ::Gitlab::Utils::Override
      include Backup::Helper

      DEFAULT_EXCLUDE = ['lost+found'].freeze

      # Use the content from stdin instead of an actual filepath (used by tar as input or output)
      USE_STDIN = '-'

      attr_reader :excludes

      # @param [IO] progress
      # @param [String] storage_path
      # @param [::Backup::Options] options
      # @param [Array] excludes
      def initialize(progress, storage_path, options:, excludes: [])
        super(progress, options: options)

        @storage_path = storage_path
        @excludes = excludes
      end

      # Copy files from public/files to backup/files
      override :dump

      def dump(backup_tarball, _)
        FileUtils.mkdir_p(backup_basepath)
        FileUtils.rm_f(backup_tarball)

        tar_utils = ::Gitlab::Backup::Cli::Utils::Tar.new
        shell_pipeline = ::Gitlab::Backup::Cli::Shell::Pipeline
        compress_command = ::Gitlab::Backup::Cli::Shell::Command.new(compress_cmd)

        if options.strategy == ::Backup::Options::Strategy::COPY
          cmd = [%w[rsync -a --delete], exclude_dirs_rsync, %W[#{storage_realpath} #{backup_basepath}]].flatten
          output, status = Gitlab::Popen.popen(cmd)

          # Retry if rsync source files vanish
          if status == 24
            $stdout.puts "Warning: files vanished during rsync, retrying..."
            output, status = Gitlab::Popen.popen(cmd)
          end

          unless status == 0
            puts output
            raise_custom_error(backup_tarball)
          end

          archive_file = [backup_tarball, 'w', 0o600]
          tar_command = tar_utils.pack_cmd(
            archive_file: USE_STDIN,
            target_directory: backup_files_realpath,
            target: '.',
            excludes: excludes)
          result = shell_pipeline.new(tar_command, compress_command).run!(output: archive_file)

          FileUtils.rm_rf(backup_files_realpath)
        else
          archive_file = [backup_tarball, 'w', 0o600]
          tar_command = tar_utils.pack_cmd(
            archive_file: USE_STDIN,
            target_directory: storage_realpath,
            target: '.',
            excludes: excludes)

          result = shell_pipeline.new(tar_command, compress_command).run!(output: archive_file)
        end

        success = pipeline_succeeded?(
          tar_status: result.status_list[0],
          compress_status: result.status_list[1],
          output: result.stderr)

        raise_custom_error(backup_tarball) unless success
      end

      override :restore

      def restore(backup_tarball, _)
        backup_existing_files_dir(backup_tarball)

        tar_utils = ::Gitlab::Backup::Cli::Utils::Tar.new
        shell_pipeline = ::Gitlab::Backup::Cli::Shell::Pipeline
        decompress_command = ::Gitlab::Backup::Cli::Shell::Command.new(decompress_cmd)

        archive_file = backup_tarball.to_s
        tar_command = tar_utils.extract_cmd(
          archive_file: USE_STDIN,
          target_directory: storage_realpath)

        result = shell_pipeline.new(decompress_command, tar_command).run!(input: archive_file)

        success = pipeline_succeeded?(
          compress_status: result.status_list[0],
          tar_status: result.status_list[1],
          output: result.stderr)

        raise Backup::Error, "Restore operation failed: #{result.stderr}" unless success
      end

      def backup_existing_files_dir(backup_tarball)
        name = File.basename(backup_tarball, '.tar.gz')
        timestamped_files_path = backup_basepath.join('tmp', "#{name}.#{Time.now.to_i}")

        return unless File.exist?(storage_realpath)

        # Move all files in the existing repos directory except . and .. to
        # repositories.<timestamp> directory
        FileUtils.mkdir_p(timestamped_files_path, mode: 0o700)

        dot_references = [File.join(storage_realpath, "."), File.join(storage_realpath, "..")]
        matching_files = Dir.glob(File.join(storage_realpath, "*"), File::FNM_DOTMATCH)
        files = matching_files - dot_references

        FileUtils.mv(files, timestamped_files_path)
      rescue Errno::EACCES
        access_denied_error(storage_realpath)
      rescue Errno::EBUSY
        resource_busy_error(storage_realpath)
      end

      def noncritical_warning?(warning)
        noncritical_warnings = [
          /^g?tar: \.: Cannot mkdir: No such file or directory$/
        ]

        noncritical_warnings.map { |w| warning =~ w }.any?
      end

      def pipeline_succeeded?(tar_status:, compress_status:, output:)
        return false unless compress_status&.success?

        tar_status&.success? || tar_ignore_non_success?(tar_status.exitstatus, output)
      end

      def tar_ignore_non_success?(exitstatus, output)
        # tar can exit with nonzero code:
        #  1 - if some files changed (i.e. a CI job is currently writes to log)
        #  2 - if it cannot create `.` directory (see issue https://gitlab.com/gitlab-org/gitlab/-/issues/22442)
        #  http://www.gnu.org/software/tar/manual/html_section/tar_19.html#Synopsis
        #  so check tar status 1 or stderr output against some non-critical warnings
        if exitstatus == 1
          $stdout.puts "Ignoring tar exit status 1 'Some files differ': #{output}"
          return true
        end

        # allow tar to fail with other non-success status if output contain non-critical warning
        if noncritical_warning?(output)
          $stdout.puts(
            "Ignoring non-success exit status #{exitstatus} due to output of non-critical warning(s): #{output}")
          return true
        end

        false
      end

      def exclude_dirs_rsync
        default = DEFAULT_EXCLUDE.map { |entry| "--exclude=#{entry}" }

        basepath = Pathname(File.basename(storage_realpath))

        default.concat(excludes.map { |entry| "--exclude=/#{basepath.join(entry)}" })
      end

      def raise_custom_error(backup_tarball)
        raise FileBackupError.new(storage_realpath, backup_tarball)
      end

      def asynchronous?
        false
      end

      private

      def storage_realpath
        @storage_realpath ||= File.realpath(@storage_path)
      end

      def backup_files_realpath
        @backup_files_realpath ||= backup_basepath.join(File.basename(@storage_path))
      end

      def backup_basepath
        Pathname(Gitlab.config.backup.path)
      end

      def access_denied_error(path)
        message = <<~ERROR

        ### NOTICE ###
        As part of restore, the task tried to move existing content from #{path}.
        However, it seems that directory contains files/folders that are not owned
        by the user #{Gitlab.config.gitlab.user}. To proceed, please move the files
        or folders inside #{path} to a secure location so that #{path} is empty and
        run restore task again.

        ERROR
        raise message
      end

      def resource_busy_error(path)
        message = <<~ERROR

        ### NOTICE ###
        As part of restore, the task tried to rename `#{path}` before restoring.
        This could not be completed, perhaps `#{path}` is a mountpoint?

        To complete the restore, please move the contents of `#{path}` to a
        different location and run the restore task again.

        ERROR
        raise message
      end
    end
  end
end
