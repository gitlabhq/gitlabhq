# frozen_string_literal: true

module Backup
  module Tasks
    class Artifacts < Task
      def self.id = 'artifacts'

      def human_name = _('artifacts')

      def destination_path = 'artifacts.tar.gz'

      private

      def target
        @target ||= ::Backup::Targets::Files.new(progress, storage_path, options: options, excludes: ['tmp'])
      end

      def storage_path
        JobArtifactUploader.root
      end
    end
  end
end
