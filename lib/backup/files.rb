require 'open3'

module Backup
  class Files
    attr_reader :name, :app_files_dir, :backup_tarball, :files_parent_dir

    def initialize(name, app_files_dir)
      @name = name
      @app_files_dir = File.realpath(app_files_dir)
      @files_parent_dir = File.realpath(File.join(@app_files_dir, '..'))
      @backup_tarball = File.join(Gitlab.config.backup.path, name + '.tar.gz')
    end

    # Copy files from public/files to backup/files
    def dump
      FileUtils.mkdir_p(Gitlab.config.backup.path)
      FileUtils.rm_f(backup_tarball)
      run_pipeline!([%W(tar -C #{app_files_dir} -cf - .), %W(gzip -c -1)], out: [backup_tarball, 'w', 0600])
    end

    def restore
      backup_existing_files_dir
      create_files_dir

      run_pipeline!([%W(gzip -cd), %W(tar -C #{app_files_dir} -xf -)], in: backup_tarball)
    end

    def backup_existing_files_dir
      timestamped_files_path = File.join(files_parent_dir, "#{name}.#{Time.now.to_i}")
      if File.exists?(app_files_dir)
        FileUtils.mv(app_files_dir, File.expand_path(timestamped_files_path))
      end
    end

    def run_pipeline!(cmd_list, options={})
      status_list = Open3.pipeline(*cmd_list, options)
      abort 'Backup failed' unless status_list.compact.all?(&:success?)
    end
  end
end
