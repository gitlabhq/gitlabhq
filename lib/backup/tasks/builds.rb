# frozen_string_literal: true

module Backup
  module Tasks
    class Builds < Task
      def self.id = 'builds'

      def human_name = _('builds')

      def destination_path = 'builds.tar.gz'

      def target
        ::Backup::Targets::Files.new(progress, app_files_dir, options: options)
      end

      private

      def app_files_dir
        Settings.gitlab_ci.builds_path
      end
    end
  end
end
