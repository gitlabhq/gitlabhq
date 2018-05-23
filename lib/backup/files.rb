require 'open3'
require_relative 'helper'

module Backup
  class Files
    include Backup::Helper

    attr_reader :name, :app_files_dir, :backup_tarball, :files_parent_dir

    def initialize(name, app_files_dir)
      @name = name
      @app_files_dir = File.realpath(app_files_dir)
      @files_parent_dir = File.realpath(File.join(@app_files_dir, '..'))
      @backup_files_dir = File.join(Gitlab.config.backup.path, File.basename(@app_files_dir) )
      @backup_tarball = File.join(Gitlab.config.backup.path, name + '.tar.gz')
    end

    # Copy files from public/files to backup/files
    def dump
      FileUtils.mkdir_p(Gitlab.config.backup.path)
      FileUtils.rm_f(backup_tarball)

      if ENV['STRATEGY'] == 'copy'
        cmd = %W(rsync -a --exclude=lost+found #{app_files_dir} #{Gitlab.config.backup.path})
        output, status = Gitlab::Popen.popen(cmd)

        unless status.zero?
          puts output
          abort 'Backup failed'
        end

        run_pipeline!([%W(tar --exclude=lost+found -C #{@backup_files_dir} -cf - .), %w(gzip -c -1)], out: [backup_tarball, 'w', 0600])
        FileUtils.rm_rf(@backup_files_dir)
      else
        run_pipeline!([%W(tar --exclude=lost+found -C #{app_files_dir} -cf - .), %w(gzip -c -1)], out: [backup_tarball, 'w', 0600])
      end
    end

    def restore
      backup_existing_files_dir

      run_pipeline!([%w(gzip -cd), %W(tar --unlink-first --recursive-unlink -C #{app_files_dir} -xf -)], in: backup_tarball)
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
      status_list = Open3.pipeline(*cmd_list, options)
      abort 'Backup failed' unless status_list.compact.all?(&:success?)
    end
  end
end
