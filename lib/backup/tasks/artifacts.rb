# frozen_string_literal: true

module Backup
  module Tasks
    class Artifacts < Task
      def self.id = 'artifacts'

      def human_name = _('artifacts')

      def destination_path = 'artifacts.tar.gz'

      def target
        excludes = ['tmp']

        ::Backup::Targets::Files.new(progress, app_files_dir, options: options, excludes: excludes)
      end

      private

      def app_files_dir
        JobArtifactUploader.root
      end
    end
  end
end
