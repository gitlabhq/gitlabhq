require 'open3'

module Backup
  class Files
    attr_reader :name, :app_files_dir, :backup_tarball, :backup_dir, :files_parent_dir

    def initialize(app_files_dir)
      @app_files_dir = File.realpath(app_files_dir)
      @name = File.basename(app_files_dir)
      @files_parent_dir = File.realpath(File.join(@app_files_dir, '..'))
      @backup_dir = Gitlab.config.backup.path
      @backup_tarball = File.join(@backup_dir, name + '.tar.gz')
    end

    # Copy files from public/files to backup/files
    def dump
      FileUtils.mkdir_p(Gitlab.config.backup.path)
      FileUtils.rm_f(backup_tarball)
      run_pipeline!([%W(tar -C #{files_parent_dir} -cf - #{name}), %W(gzip -c -1)], out: [backup_tarball, 'w', 0600])
    end

    def restore
      backup_existing_files_dir

      run_pipeline!([%W(gzip -cd), %W(tar -C #{files_parent_dir} -xf -)], in: backup_tarball)
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
