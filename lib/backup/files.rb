# frozen_string_literal: true

require 'open3'

module Backup
  class Files < Task
    extend ::Gitlab::Utils::Override
    include Backup::Helper

    DEFAULT_EXCLUDE = 'lost+found'

    attr_reader :excludes

    def initialize(progress, app_files_dir, excludes: [])
      super(progress)

      @app_files_dir = app_files_dir
      @excludes = [DEFAULT_EXCLUDE].concat(excludes)
    end

    # Copy files from public/files to backup/files
    override :dump
    def dump(backup_tarball, backup_id)
      FileUtils.mkdir_p(Gitlab.config.backup.path)
      FileUtils.rm_f(backup_tarball)

      if ENV['STRATEGY'] == 'copy'
        cmd = [%w[rsync -a --delete], exclude_dirs(:rsync), %W[#{app_files_realpath} #{Gitlab.config.backup.path}]].flatten
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

        tar_cmd = [tar, exclude_dirs(:tar), %W[-C #{backup_files_realpath} -cf - .]].flatten
        status_list, output = run_pipeline!([tar_cmd, gzip_cmd], out: [backup_tarball, 'w', 0600])
        FileUtils.rm_rf(backup_files_realpath)
      else
        tar_cmd = [tar, exclude_dirs(:tar), %W[-C #{app_files_realpath} -cf - .]].flatten
        status_list, output = run_pipeline!([tar_cmd, gzip_cmd], out: [backup_tarball, 'w', 0600])
      end

      unless pipeline_succeeded?(tar_status: status_list[0], gzip_status: status_list[1], output: output)
        raise_custom_error(backup_tarball)
      end
    end

    override :restore
    def restore(backup_tarball)
      backup_existing_files_dir(backup_tarball)

      cmd_list = [%w[gzip -cd], %W[#{tar} --unlink-first --recursive-unlink -C #{app_files_realpath} -xf -]]
      status_list, output = run_pipeline!(cmd_list, in: backup_tarball)
      unless pipeline_succeeded?(gzip_status: status_list[0], tar_status: status_list[1], output: output)
        raise Backup::Error, "Restore operation failed: #{output}"
      end
    end

    def tar
      if system(*%w[gtar --version], out: '/dev/null')
        # It looks like we can get GNU tar by running 'gtar'
        'gtar'
      else
        'tar'
      end
    end

    def backup_existing_files_dir(backup_tarball)
      name = File.basename(backup_tarball, '.tar.gz')

      timestamped_files_path = File.join(Gitlab.config.backup.path, "tmp", "#{name}.#{Time.now.to_i}")
      if File.exist?(app_files_realpath)
        # Move all files in the existing repos directory except . and .. to
        # repositories.<timestamp> directory
        FileUtils.mkdir_p(timestamped_files_path, mode: 0700)
        files = Dir.glob(File.join(app_files_realpath, "*"), File::FNM_DOTMATCH) - [File.join(app_files_realpath, "."), File.join(app_files_realpath, "..")]
        begin
          FileUtils.mv(files, timestamped_files_path)
        rescue Errno::EACCES
          access_denied_error(app_files_realpath)
        rescue Errno::EBUSY
          resource_busy_error(app_files_realpath)
        end
      end
    end

    def run_pipeline!(cmd_list, options = {})
      err_r, err_w = IO.pipe
      options[:err] = err_w
      status_list = Open3.pipeline(*cmd_list, options)
      err_w.close

      [status_list, err_r.read]
    end

    def noncritical_warning?(warning)
      noncritical_warnings = [
        /^g?tar: \.: Cannot mkdir: No such file or directory$/
      ]

      noncritical_warnings.map { |w| warning =~ w }.any?
    end

    def pipeline_succeeded?(tar_status:, gzip_status:, output:)
      return false unless gzip_status&.success?

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
        $stdout.puts "Ignoring non-success exit status #{exitstatus} due to output of non-critical warning(s): #{output}"
        return true
      end

      false
    end

    def exclude_dirs(fmt)
      excludes.map do |s|
        if s == DEFAULT_EXCLUDE
          '--exclude=' + s
        elsif fmt == :rsync
          '--exclude=/' + File.join(File.basename(app_files_realpath), s)
        elsif fmt == :tar
          '--exclude=./' + s
        end
      end
    end

    def raise_custom_error(backup_tarball)
      raise FileBackupError.new(app_files_realpath, backup_tarball)
    end

    private

    def app_files_realpath
      @app_files_realpath ||= File.realpath(@app_files_dir)
    end

    def backup_files_realpath
      @backup_files_realpath ||= File.join(Gitlab.config.backup.path, File.basename(@app_files_dir))
    end
  end
end
