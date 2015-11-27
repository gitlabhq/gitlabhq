require 'backup/files'

module Backup
  class Composer < Files
    attr_reader :app_packages_json

    def initialize
      super('composer', Rails.root.join('public/p'))
      @app_packages_json = File.join(@files_parent_dir, 'packages.json')
    end

    # Backup public/packages.json and public/p to backup/composer.tar.gz
    def dump
      # Make sure we have a backup dir
      FileUtils.mkdir_p(Gitlab.config.backup.path)

      # Remove existing backup tarball
      FileUtils.rm_f(backup_tarball)

      # Create backup tarball
      run_pipeline!([%W(tar -cf - -C #{app_files_dir} . -C #{files_parent_dir} packages.json), %W(gzip -c -1)], out: [backup_tarball, 'w', 0600])

    end

    def restore
      # Move existing public/packages.json to public/packages.timestamp.json
      backup_existing_packages_json

      # Move existing public/p to public/p.timestamp
      backup_existing_packages_dir

      # Create packages dir
      Dir.mkdir(app_files_dir, 0700)

      # Restore packages contents
      run_pipeline!([%W(gzip -cd), %W(tar -C #{app_files_dir} -xf -)], in: backup_tarball)

      # Restore packages.json to parent folder
      FileUtils.mv(File.join(app_files_dir, 'packages.json'), app_packages_json)
    end

    # Move public/packages.json to public/packages.timestamp.json
    def backup_existing_packages_json
      timestamped_packages_json = File.join(files_parent_dir, "packages.#{Time.now.to_i}.json")
      if File.exists?(app_packages_json)
        FileUtils.mv(app_packages_json, File.expand_path(timestamped_packages_json))
      end
    end

    # Move public/p to public/p.timestamp
    def backup_existing_packages_dir
      timestamped_packages_dir = File.join(files_parent_dir, "p.#{Time.now.to_i}")
      if File.exists?(app_files_dir)
        FileUtils.mv(app_files_dir, File.expand_path(timestamped_packages_dir))
      end
    end
  end
end
