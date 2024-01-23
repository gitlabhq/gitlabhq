# frozen_string_literal: true

module Backup
  module Tasks
    class Uploads < Task
      def self.id = 'uploads'

      def human_name = _('uploads')

      def destination_path = 'uploads.tar.gz'

      def target
        excludes = ['tmp']

        ::Backup::Targets::Files.new(progress, app_files_dir, options: options, excludes: excludes)
      end

      private

      def app_files_dir
        File.join(Gitlab.config.uploads.storage_path, 'uploads')
      end
    end
  end
end
