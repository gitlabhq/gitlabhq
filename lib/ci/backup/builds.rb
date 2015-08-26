module Ci
  module Backup
    class Builds
      attr_reader :app_builds_dir, :backup_builds_dir, :backup_dir

      def initialize
        @app_builds_dir = File.realpath(Rails.root.join('ci/builds'))
        @backup_dir = GitlabCi.config.backup.path
        @backup_builds_dir = File.join(GitlabCi.config.backup.path, 'ci/builds')
      end

      # Copy builds from builds directory to backup/builds
      def dump
        FileUtils.mkdir_p(backup_builds_dir)
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
end
