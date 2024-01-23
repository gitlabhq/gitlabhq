# frozen_string_literal: true

module Backup
  module Tasks
    class Packages < Task
      def self.id = 'packages'

      def human_name = _('packages')

      def destination_path = 'packages.tar.gz'

      def target
        excludes = ['tmp']

        ::Backup::Targets::Files.new(progress, app_files_dir, options: options, excludes: excludes)
      end

      private

      def app_files_dir
        Settings.packages.storage_path
      end
    end
  end
end
