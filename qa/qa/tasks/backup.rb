require 'mkmf'

module QA
  module Tasks
    class Backup
      BACKUP_SUFFIX = '_gitlab_backup.tar'.freeze

      attr_accessor :backup_path

      def initialize(path)
        @backup_path = path
      end

      def create_backup
        run_rake('gitlab:backup:create')
      end

      def list_backups
        glob_path = File.join(backup_path, "*#{BACKUP_SUFFIX}")
        files = Dir.glob(glob_path)

        files.map { |filename| File.basename(filename).gsub(%r(#{BACKUP_SUFFIX}$), '') }
      end

      def restore_backup(version)
        run_rake('gitlab:backup:restore BACKUP=#{version}')
      end

      def run_rake(command)
        stdout = `#{find_rake} #{command}`
        [stdout, $?.exitstatus]
      end

      def find_rake
        @rake ||= find_executable('gitlab-rake') || find_executable('rake')

        raise 'Could not find rake in PATH' unless @rake

        @rake
      end
    end
  end
end
