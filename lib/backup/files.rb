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
        cmd = [%w(rsync -a), exclude_dirs(:rsync), %W(#{app_files_dir} #{Gitlab.config.backup.path})].flatten
        output, status = Gitlab::Popen.popen(cmd)

        unless status == 0
          puts output
          raise Backup::Error, 'Backup failed'
        end

        tar_cmd = [tar, exclude_dirs(:tar), %W(-C #{@backup_files_dir} -cf - .)].flatten
        run_pipeline!([tar_cmd, gzip_cmd], out: [backup_tarball, 'w', 0600])
        FileUtils.rm_rf(@backup_files_dir)
      else
        tar_cmd = [tar, exclude_dirs(:tar), %W(-C #{app_files_dir} -cf - .)].flatten
        run_pipeline!([tar_cmd, gzip_cmd], out: [backup_tarball, 'w', 0600])
      end
    end

    def restore
      backup_existing_files_dir

      run_pipeline!([%w(gzip -cd), %W(#{tar} --unlink-first --recursive-unlink -C #{app_files_dir} -xf -)], in: backup_tarball)
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
      status = Open3.pipeline(*cmd_list, options)
      err_w.close
      return if status.compact.all?(&:success?)

      regex = /^g?tar: \.: Cannot mkdir: No such file or directory$/
      error = err_r.read
      raise Backup::Error, "Backup failed. #{error}" unless error =~ regex
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
