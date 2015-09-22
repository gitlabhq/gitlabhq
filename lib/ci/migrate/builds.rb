module Ci
  module Migrate
    class Builds
      attr_reader :app_builds_dir, :backup_builds_tarball, :backup_dir

      def initialize
        @app_builds_dir = Settings.gitlab_ci.builds_path
        @backup_dir = Gitlab.config.backup.path
        @backup_builds_tarball = File.join(backup_dir, 'builds/builds.tar.gz')
      end

      def restore
        backup_existing_builds_dir

        FileUtils.mkdir_p(app_builds_dir, mode: 0700)
        unless system('tar', '-C', app_builds_dir, '-zxf', backup_builds_tarball)
          abort 'Restore failed'.red
        end
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
