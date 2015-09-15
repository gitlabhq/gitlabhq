module Backup
  class Builds
    attr_reader :app_builds_dir, :backup_builds_dir, :backup_dir

    def initialize
      @app_builds_dir = Settings.gitlab_ci.builds_path
      @backup_dir = Gitlab.config.backup.path
      @backup_builds_dir = File.join(Gitlab.config.backup.path, 'builds')
    end

    # Copy builds from builds directory to backup/builds
    def dump
      FileUtils.rm_rf(backup_builds_dir)
      # Ensure the parent dir of backup_builds_dir exists
      FileUtils.mkdir_p(Gitlab.config.backup.path)
      # Fail if somebody raced to create backup_builds_dir before us
      FileUtils.mkdir(backup_builds_dir, mode: 0700)
      FileUtils.cp_r(app_builds_dir, backup_dir)
    end

    def restore
      backup_existing_builds_dir

      FileUtils.cp_r(backup_builds_dir, app_builds_dir)
    end

    def backup_existing_builds_dir
      timestamped_builds_path = File.join(app_builds_dir, '..', "builds.#{Time.now.to_i}")
      if File.exists?(app_builds_dir)
        FileUtils.mv(app_builds_dir, File.expand_path(timestamped_builds_path))
      end
    end
  end
end
