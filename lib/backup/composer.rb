require 'open3'

module Backup
  class Composer
    attr_reader :name, :app_packages_json, :app_packages_dir, :app_packages_parent_dir, :backup_tarball

    def initialize
      @name = 'composer'
      @app_packages_dir = File.realpath(Rails.root.join('public/p'))
      @app_packages_parent_dir = File.realpath(File.join(@app_packages_dir, '..'))
      @app_packages_json = File.join(@app_packages_parent_dir, 'packages.json')
      @backup_tarball = File.join(Gitlab.config.backup.path, name + '.tar.gz')
    end

    # Backup public/packages.json and public/p to backup/composer.tar.gz
    def dump
      # Make sure we have a backup dir
      FileUtils.mkdir_p(Gitlab.config.backup.path)

      # Remove existing backup tarball
      FileUtils.rm_f(backup_tarball)

      # Create backup tarball
      run_pipeline!([%W(tar -cf - -C #{app_packages_dir} . -C #{app_packages_parent_dir} packages.json), %W(gzip -c -1)], out: [backup_tarball, 'w', 0600])

    end

    def restore
      # Move existing public/packages.json to public/packages.timestamp.json
      backup_existing_packages_json

      # Move existing public/p to public/p.timestamp
      backup_existing_packages_dir

      # Create packages dir
      Dir.mkdir(app_packages_dir, 0700)

      # Restore packages contents
      run_pipeline!([%W(gzip -cd), %W(tar -C #{app_packages_dir} -xf -)], in: backup_tarball)

      # Restore packages.json to parent folder
      FileUtils.mv(File.join(app_packages_dir, 'packages.json'), app_packages_json)
    end

    # Move public/packages.json to public/packages.timestamp.json
    def backup_existing_packages_json
      timestamped_packages_json = File.join(app_packages_parent_dir, "packages.#{Time.now.to_i}.json")
      if File.exists?(app_packages_json)
        FileUtils.mv(app_packages_json, File.expand_path(timestamped_packages_json))
      end
    end

    # Move public/p to public/p.timestamp
    def backup_existing_packages_dir
      timestamped_packages_dir = File.join(app_packages_parent_dir, "p.#{Time.now.to_i}")
      if File.exists?(app_packages_dir)
        FileUtils.mv(app_packages_dir, File.expand_path(timestamped_packages_dir))
      end
    end

    def run_pipeline!(cmd_list, options={})
      status_list = Open3.pipeline(*cmd_list, options)
      abort 'Backup failed' unless status_list.compact.all?(&:success?)
    end
  end
end
