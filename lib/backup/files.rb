# frozen_string_literal: true

require 'open3'
require_relative 'helper'

module Backup
  class Files
    include Backup::Helper

    DEFAULT_EXCLUDE = 'lost+found'

    attr_reader :name, :app_files_dir, :backup_tarball, :excludes, :files_parent_dir

    def initialize(name, app_files_dir, excludes: [])
      @name = name
      @app_files_dir = File.realpath(app_files_dir)
      @files_parent_dir = File.realpath(File.join(@app_files_dir, '..'))
      @backup_files_dir = File.join(Gitlab.config.backup.path, File.basename(@app_files_dir) )
      @backup_tarball = File.join(Gitlab.config.backup.path, name + '.tar.gz')
      @excludes = [DEFAULT_EXCLUDE].concat(excludes)
    end

    # Copy files from public/files to backup/files
    def dump
      FileUtils.mkdir_p(Gitlab.config.backup.path)
      FileUtils.rm_f(backup_tarball)

      if ENV['STRATEGY'] == 'copy'
        cmd = [%w[rsync -a], exclude_dirs(:rsync), %W[#{app_files_dir} #{Gitlab.config.backup.path}]].flatten
        output, status = Gitlab::Popen.popen(cmd)

        unless status == 0
          puts output
          raise Backup::Error, 'Backup failed'
        end

        tar_cmd = [tar, exclude_dirs(:tar), %W[-C #{@backup_files_dir} -cf - .]].flatten
        status_list, output = run_pipeline!([tar_cmd, gzip_cmd], out: [backup_tarball, 'w', 0600])
        FileUtils.rm_rf(@backup_files_dir)
      else
        tar_cmd = [tar, exclude_dirs(:tar), %W[-C #{app_files_dir} -cf - .]].flatten
        status_list, output = run_pipeline!([tar_cmd, gzip_cmd], out: [backup_tarball, 'w', 0600])
      end

      unless pipeline_succeeded?(tar_status: status_list[0], gzip_status: status_list[1], output: output)
        raise Backup::Error, "Backup operation failed: #{output}"
      end
    end

    def restore
      backup_existing_files_dir

      cmd_list = [%w[gzip -cd], %W[#{tar} --unlink-first --recursive-unlink -C #{app_files_dir} -xf -]]
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

    def backup_existing_files_dir
      timestamped_files_path = File.join(Gitlab.config.backup.path, "tmp", "#{name}.#{Time.now.to_i}")
      if File.exist?(app_files_dir)
        # Move all files in the existing repos directory except . and .. to
        # repositories.old.<timestamp> directory
        FileUtils.mkdir_p(timestamped_files_path, mode: 0700)
        files = Dir.glob(File.join(app_files_dir, "*"), File::FNM_DOTMATCH) - [File.join(app_files_dir, "."), File.join(app_files_dir, "..")]
        begin
          FileUtils.mv(files, timestamped_files_path)
        rescue Errno::EACCES
          access_denied_error(app_files_dir)
        rescue Errno::EBUSY
          resource_busy_error(app_files_dir)
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
          '--exclude=/' + s
        elsif fmt == :tar
          '--exclude=./' + s
        end
      end
    end
  end
end
